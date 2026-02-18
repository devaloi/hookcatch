# Build hookcatch — Rails Webhook Receiver

You are building a **portfolio project** for a Senior AI Engineer's public GitHub. It must be impressive, clean, and production-grade. Read these docs before writing any code:

1. **`R03-rails-webhook-catcher.md`** — Complete project spec: architecture, phases, provider pattern, signature verification, commit plan. This is your primary blueprint. Follow it phase by phase.
2. **`github-portfolio.md`** — Portfolio goals and Definition of Done (Level 1 + Level 2). Understand the quality bar.
3. **`github-portfolio-checklist.md`** — Pre-publish checklist. Every item must pass before you're done.

---

## Instructions

### Read first, build second
Read all three docs completely before writing a single line of code. Understand the provider pattern for signature verification, the immediate-ACK + async-process flow, the dead letter queue, and the idempotency design.

### Follow the phases in order
The project spec has 5 phases. Do them in order:
1. **Scaffold & Models** — Rails API app, RSpec setup, WebhookDelivery and DeadLetter models
2. **Signature Verification** — provider pattern: GitHub (HMAC-SHA256), Stripe (timestamp + signature), generic HMAC. Timing-safe comparison.
3. **Controller & Processing** — webhook controller (verify → store → enqueue → 200), ProcessWebhookJob with retry + dead letter, WebhookProcessor routing, example handlers
4. **Admin Endpoints & Tests** — JWT-protected admin routes (list, detail, replay), comprehensive RSpec suite, edge cases
5. **Refactor & Polish** — extract shared patterns, clean error hierarchy, rubocop pass, README with curl examples

### Commit frequently
Follow the commit plan in the spec. Use **conventional commits**. Each commit should be a logical unit.

### Quality non-negotiables
- **Immediate ACK.** Controller returns 200 immediately after verification and storage. Processing happens in background via ActiveJob. This is the correct webhook pattern — never make the sender wait.
- **HMAC signature verification.** Each provider verifies differently: GitHub uses X-Hub-Signature-256, Stripe uses Stripe-Signature with timestamp, generic uses configurable header. All use timing-safe comparison (`ActiveSupport::SecurityUtils.secure_compare`).
- **Idempotent processing.** Delivery ID from provider headers. Duplicate deliveries return 200 without re-processing. Safe to replay.
- **Dead letter queue.** After N failed attempts (configurable), delivery moves to dead_letters table. Admin can inspect and replay. Failed webhooks are never silently lost.
- **Provider pattern.** New providers (e.g., Shopify, Twilio) added by creating a new class. No controller changes needed.
- **Rails API mode.** Lean Rails — no views, no asset pipeline, no ActionCable. Pure API microservice.
- **RSpec + FactoryBot.** Controller specs, service specs, model specs, job specs. Use `webhook_helpers.rb` for generating properly signed test payloads.
- **Lint clean.** RuboCop + rubocop-rails must pass. Zero offenses.
- **No Docker.** Just `bundle install`, `rails db:migrate`, `rails server`.

### What NOT to do
- Don't process webhooks synchronously in the controller. Enqueue and return 200.
- Don't use `Digest::SHA256` without `secure_compare`. Timing attacks are real.
- Don't hardcode provider secrets. Use environment variables.
- Don't skip the dead letter queue. Production webhook systems need this.
- Don't commit `config/master.key`, `.env`, or database files.
- Don't leave `# TODO` or `# FIXME` comments anywhere.

---

## GitHub Username

The GitHub username is **devaloi**. For any GitHub URLs, use `github.com/devaloi/hookcatch`.

## Start

Read the three docs. Then begin Phase 1 from `R03-rails-webhook-catcher.md`.
