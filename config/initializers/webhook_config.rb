Rails.application.config.webhook_secrets = {
  github: ENV.fetch("GITHUB_WEBHOOK_SECRET", ""),
  stripe: ENV.fetch("STRIPE_WEBHOOK_SECRET", ""),
  generic: ENV.fetch("GENERIC_WEBHOOK_SECRET", "")
}.freeze

Rails.application.config.jwt_secret = ENV.fetch("JWT_SECRET", "")
