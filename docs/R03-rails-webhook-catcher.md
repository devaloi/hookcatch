# R03: hookcatch — Rails Webhook Receiver

**Catalog ID:** R03 | **Size:** S | **Language:** Ruby/Rails
**Repo name:** `hookcatch`
**One-liner:** A webhook ingestion service built with Rails API mode — signature verification, idempotent processing, async job handling, and dead letter queue for failed deliveries.

---

## Why This Stands Out

- **Signature verification** for GitHub, Stripe, and generic HMAC — shows security awareness
- **Idempotent processing** — deduplication via delivery ID, safe to replay
- **Async processing** — webhooks acknowledged fast (200), processed in background via ActiveJob
- **Dead letter queue** — failed webhooks stored for inspection and manual replay
- **Multi-provider** — provider-specific parsers (GitHub events, Stripe events, generic JSON)
- **Rails API mode** — lean, no views, no asset pipeline — proper microservice
- **Request logging** — full payload capture for debugging, with automatic cleanup

---

## Architecture

```
hookcatch/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── webhooks_controller.rb      # Receive + verify + enqueue
│   ├── jobs/
│   │   ├── application_job.rb
│   │   └── process_webhook_job.rb      # Async webhook processing
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── webhook_delivery.rb         # AR model: payload, status, attempts
│   │   └── dead_letter.rb             # Failed deliveries for replay
│   ├── services/
│   │   ├── signature_verifier.rb       # HMAC verification per provider
│   │   ├── webhook_processor.rb        # Route event to handler
│   │   └── providers/
│   │       ├── base_provider.rb        # Abstract provider interface
│   │       ├── github_provider.rb      # GitHub webhook parsing + verification
│   │       ├── stripe_provider.rb      # Stripe webhook parsing + verification
│   │       └── generic_provider.rb     # Generic HMAC-SHA256 verification
│   └── handlers/
│       ├── base_handler.rb             # Handler interface
│       ├── github/
│       │   ├── push_handler.rb         # Handle push events
│       │   └── pull_request_handler.rb # Handle PR events
│       └── stripe/
│           ├── payment_handler.rb      # Handle payment events
│           └── subscription_handler.rb # Handle subscription events
├── config/
│   ├── routes.rb                       # POST /webhooks/:provider
│   ├── database.yml
│   └── initializers/
│       └── webhook_config.rb           # Provider secrets from ENV
├── db/
│   └── migrate/
│       ├── 001_create_webhook_deliveries.rb
│       └── 002_create_dead_letters.rb
├── spec/
│   ├── controllers/
│   │   └── webhooks_controller_spec.rb
│   ├── services/
│   │   ├── signature_verifier_spec.rb
│   │   └── webhook_processor_spec.rb
│   ├── models/
│   │   ├── webhook_delivery_spec.rb
│   │   └── dead_letter_spec.rb
│   ├── jobs/
│   │   └── process_webhook_job_spec.rb
│   └── support/
│       └── webhook_helpers.rb          # Test payload generators
├── Gemfile
├── Makefile
├── .rubocop.yml
├── .gitignore
├── LICENSE
└── README.md
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/webhooks/:provider` | Receive webhook (github, stripe, generic) |
| `GET` | `/webhooks/deliveries` | List recent deliveries (admin, JWT-protected) |
| `GET` | `/webhooks/deliveries/:id` | Get delivery details + payload |
| `POST` | `/webhooks/deliveries/:id/replay` | Replay a failed delivery |
| `GET` | `/webhooks/dead_letters` | List dead letter entries |
| `GET` | `/health` | Health check |

---

## Key Design Decisions

**Immediate ACK, async process:** Controller verifies signature, stores delivery, enqueues job, returns 200 immediately. Processing happens in background. This prevents timeouts and allows retries.

**Provider pattern:** Each provider (GitHub, Stripe, generic) implements `verify_signature(request)` and `parse_event(payload)`. New providers are added by creating a new class — no changes to controller.

**Idempotency:** Each delivery has a unique `delivery_id` (from provider headers or generated). Duplicate deliveries are detected and skipped. Safe to replay.

**Dead letter queue:** After N failed attempts (configurable, default 3), delivery moves to dead_letters table with error details. Admin can inspect and manually replay.

---

## Phases

### Phase 1: Scaffold & Models

**1.1 — Rails API setup**
- `rails new hookcatch --api --database=sqlite3 -T` (skip default tests, use RSpec)
- Add gems: rspec-rails, factory_bot_rails, shoulda-matchers, rubocop-rails
- Configure RSpec, FactoryBot

**1.2 — WebhookDelivery model**
- Fields: `provider` (string), `delivery_id` (string, unique index), `event_type` (string), `payload` (json), `headers` (json), `status` (enum: pending/processing/completed/failed/dead), `attempts` (integer, default 0), `error_message` (text), `processed_at` (datetime)
- Scopes: `recent`, `failed`, `by_provider`, `pending`
- Validations: provider required, delivery_id unique

**1.3 — DeadLetter model**
- Fields: `webhook_delivery_id` (reference), `error_class` (string), `error_message` (text), `backtrace` (text), `failed_at` (datetime)
- Belongs to webhook_delivery

### Phase 2: Signature Verification

**2.1 — Base verifier**
- `SignatureVerifier.verify!(provider:, request:)` dispatches to provider
- Raises `SignatureVerifier::InvalidSignature` on failure

**2.2 — GitHub provider**
- Read `X-Hub-Signature-256` header
- Compute HMAC-SHA256 of raw body with secret
- Secure compare (timing-safe)
- Parse event type from `X-GitHub-Event` header
- Delivery ID from `X-GitHub-Delivery` header

**2.3 — Stripe provider**
- Read `Stripe-Signature` header (contains timestamp + signature)
- Compute expected signature: `HMAC-SHA256("#{timestamp}.#{raw_body}", secret)`
- Verify timestamp is within tolerance (5 minutes)
- Parse event type from `payload["type"]`
- Delivery ID from `payload["id"]`

**2.4 — Generic provider**
- Read `X-Signature-256` header (or configurable header name)
- HMAC-SHA256 verification
- Event type from `payload["event"]` or `payload["type"]`
- Delivery ID from `X-Delivery-ID` header or generate UUID

### Phase 3: Controller & Processing

**3.1 — WebhooksController**
- `POST /webhooks/:provider` — verify signature, check idempotency, store delivery, enqueue job, return 200
- Read raw body for signature verification (before Rails parses JSON)
- Rescue `InvalidSignature` → 401
- Rescue `DuplicateDelivery` → 200 (acknowledge silently)
- Log: provider, event_type, delivery_id

**3.2 — ProcessWebhookJob**
- Find delivery, update status to `processing`
- Route to handler via `WebhookProcessor.process(delivery)`
- On success: update status to `completed`, set `processed_at`
- On failure: increment attempts, update error_message
- After max attempts: move to dead letters, set status to `dead`
- Retry with exponential backoff: 30s, 2min, 10min

**3.3 — WebhookProcessor**
- Registry mapping `{provider}:{event_type}` → handler class
- `process(delivery)` finds and calls appropriate handler
- Unknown events logged and marked completed (don't fail on unknown)

**3.4 — Example handlers**
- `GitHub::PushHandler` — logs repo, branch, commit count
- `Stripe::PaymentHandler` — logs amount, currency, status
- Handlers are minimal — this is about the infrastructure, not business logic

### Phase 4: Admin Endpoints & Tests

**4.1 — Admin routes**
- JWT auth middleware (simple, shared secret from ENV)
- `GET /webhooks/deliveries` — paginated list, filter by provider/status
- `GET /webhooks/deliveries/:id` — full details
- `POST /webhooks/deliveries/:id/replay` — re-enqueue for processing
- `GET /webhooks/dead_letters` — list with error details

**4.2 — Comprehensive tests**
- Controller specs: valid signature → 200 + job enqueued, invalid → 401, duplicate → 200
- Signature verifier specs: each provider, valid/invalid/missing, timing-safe
- Model specs: validations, scopes, status transitions
- Job specs: success flow, failure + retry, dead letter after max attempts
- Use `webhook_helpers.rb` for generating signed test payloads

**4.3 — Edge cases**
- Empty body
- Malformed JSON
- Missing signature header
- Expired Stripe timestamp
- Concurrent duplicate deliveries (race condition on idempotency check)

### Phase 5: Refactor & Polish

- Extract shared verification logic into concern
- Ensure all error classes inherit from a base error
- Pagination helper for list endpoints
- Rubocop clean pass
- README with curl examples for each provider
- Health endpoint

---

## Tech Stack

| Component | Choice |
|-----------|--------|
| Framework | Rails 7.1+ (API mode) |
| Database | SQLite (development) |
| Background jobs | ActiveJob with async adapter |
| Auth (admin) | JWT (simple shared secret) |
| Testing | RSpec + FactoryBot |
| Linting | RuboCop + rubocop-rails |

---

## Commit Plan

1. `feat: scaffold Rails API with RSpec and models`
2. `feat: add WebhookDelivery and DeadLetter models with migrations`
3. `feat: add signature verification for GitHub, Stripe, generic`
4. `feat: add webhooks controller with signature check and idempotency`
5. `feat: add ProcessWebhookJob with retry and dead letter logic`
6. `feat: add WebhookProcessor with handler routing`
7. `feat: add example handlers for GitHub push and Stripe payment`
8. `feat: add admin endpoints with JWT auth`
9. `test: add controller, service, model, and job specs`
10. `refactor: extract shared patterns, clean up error hierarchy`
11. `docs: add README with architecture, curl examples, and setup`
12. `chore: rubocop clean pass and final polish`
