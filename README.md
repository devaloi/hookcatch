# hookcatch

[![CI](https://github.com/devaloi/hookcatch/actions/workflows/ci.yml/badge.svg)](https://github.com/devaloi/hookcatch/actions/workflows/ci.yml)

A webhook ingestion service built with Rails API mode — signature verification, idempotent processing, async job handling, and dead letter queue for failed deliveries.

## Architecture

```
POST /webhooks/:provider
       │
       ▼
┌──────────────────┐
│ WebhooksController│ ── verify signature (HMAC-SHA256)
│                  │ ── check idempotency (delivery_id)
│                  │ ── store WebhookDelivery
│                  │ ── enqueue ProcessWebhookJob
│                  │ ── return 200 immediately
└──────────────────┘
       │
       ▼ (async)
┌──────────────────┐
│ ProcessWebhookJob│ ── route to handler via WebhookProcessor
│                  │ ── success → completed
│                  │ ── failure → retry with backoff
│                  │ ── max retries → DeadLetter
└──────────────────┘
       │
       ▼
┌──────────────────┐
│    Handlers      │ ── Github::PushHandler
│                  │ ── Github::PullRequestHandler
│                  │ ── Stripe::PaymentHandler
│                  │ ── Stripe::SubscriptionHandler
└──────────────────┘
```

## Features

- **Multi-provider** signature verification (GitHub, Stripe, generic HMAC-SHA256)
- **Idempotent** — duplicate delivery IDs are silently acknowledged
- **Async processing** — webhooks are ACK'd immediately, processed in background
- **Dead letter queue** — failed webhooks stored for inspection and replay
- **JWT-protected admin** — list, inspect, and replay deliveries
- **Health endpoint** — `/health` for load balancers

## Setup

```bash
git clone https://github.com/devaloi/hookcatch.git && cd hookcatch
cp .env.example .env    # edit with your secrets
bundle install
rails db:create db:migrate
make server
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GITHUB_WEBHOOK_SECRET` | GitHub webhook HMAC secret |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret |
| `GENERIC_WEBHOOK_SECRET` | Generic HMAC-SHA256 secret |
| `JWT_SECRET` | Secret for admin JWT tokens |

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/webhooks/:provider` | Signature | Receive webhook |
| `GET` | `/webhooks/deliveries` | JWT | List deliveries |
| `GET` | `/webhooks/deliveries/:id` | JWT | Delivery details |
| `POST` | `/webhooks/deliveries/:id/replay` | JWT | Replay delivery |
| `GET` | `/webhooks/dead_letters` | JWT | List dead letters |
| `GET` | `/health` | None | Health check |

## curl Examples

### Generate a JWT token (for admin endpoints)

```bash
# Using Ruby to generate a token:
ruby -e '
  require "openssl"; require "base64"; require "json"
  secret = "your_jwt_secret_min_32_chars_long"
  header = Base64.urlsafe_encode64({"alg":"HS256","typ":"JWT"}.to_json).tr("=","")
  payload = Base64.urlsafe_encode64({"exp":(Time.now.to_i+3600)}.to_json).tr("=","")
  sig = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256",secret,"#{header}.#{payload}")).tr("=","")
  puts "#{header}.#{payload}.#{sig}"
'
```

### Send a GitHub webhook

```bash
BODY='{"ref":"refs/heads/main","repository":{"full_name":"owner/repo"},"commits":[{"id":"abc123","message":"test"}]}'
SIG=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$GITHUB_WEBHOOK_SECRET" | sed 's/.*= //')

curl -X POST http://localhost:3000/webhooks/github \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$SIG" \
  -H "X-GitHub-Delivery: $(uuidgen)" \
  -H "X-GitHub-Event: push" \
  -d "$BODY"
```

### Send a Stripe webhook

```bash
BODY='{"id":"evt_123","type":"payment_intent.succeeded","data":{"object":{"amount":2000,"currency":"usd","status":"succeeded"}}}'
TIMESTAMP=$(date +%s)
SIG=$(echo -n "${TIMESTAMP}.${BODY}" | openssl dgst -sha256 -hmac "$STRIPE_WEBHOOK_SECRET" | sed 's/.*= //')

curl -X POST http://localhost:3000/webhooks/stripe \
  -H "Content-Type: application/json" \
  -H "Stripe-Signature: t=$TIMESTAMP,v1=$SIG" \
  -d "$BODY"
```

### Send a generic webhook

```bash
BODY='{"event":"user.created","data":{"user_id":123,"email":"test@example.com"}}'
SIG=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$GENERIC_WEBHOOK_SECRET" | sed 's/.*= //')

curl -X POST http://localhost:3000/webhooks/generic \
  -H "Content-Type: application/json" \
  -H "X-Signature-256: sha256=$SIG" \
  -H "X-Delivery-ID: $(uuidgen)" \
  -d "$BODY"
```

### List deliveries (admin)

```bash
curl http://localhost:3000/webhooks/deliveries \
  -H "Authorization: Bearer $JWT_TOKEN"
```

### Replay a failed delivery

```bash
curl -X POST http://localhost:3000/webhooks/deliveries/1/replay \
  -H "Authorization: Bearer $JWT_TOKEN"
```

### Health check

```bash
curl http://localhost:3000/health
```

## Testing

```bash
make test
# or
bundle exec rspec
```

## Tech Stack

- **Ruby** 3.4.4 / **Rails** 8.1.2 (API mode)
- **SQLite** for storage
- **ActiveJob** (async adapter) for background processing
- **RSpec** + **FactoryBot** for testing

## License

MIT — see [LICENSE](LICENSE)
