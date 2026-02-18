module WebhookHelpers
  GITHUB_SECRET = "test_github_secret"
  STRIPE_SECRET = "test_stripe_secret"
  GENERIC_SECRET = "test_generic_secret"
  JWT_SECRET = "test_jwt_secret"

  def setup_webhook_secrets
    Rails.application.config.webhook_secrets = {
      github: GITHUB_SECRET,
      stripe: STRIPE_SECRET,
      generic: GENERIC_SECRET
    }
    Rails.application.config.jwt_secret = JWT_SECRET
  end

  def github_payload(overrides = {})
    {
      ref: "refs/heads/main",
      repository: { full_name: "owner/repo" },
      commits: [
        { id: "abc123", message: "Test commit" }
      ]
    }.merge(overrides)
  end

  def github_pr_payload(overrides = {})
    {
      action: "opened",
      pull_request: {
        number: 42,
        title: "Fix the thing"
      }
    }.merge(overrides)
  end

  def stripe_payment_payload(overrides = {})
    {
      id: "evt_#{SecureRandom.hex(8)}",
      type: "payment_intent.succeeded",
      data: {
        object: {
          amount: 2000,
          currency: "usd",
          status: "succeeded"
        }
      }
    }.merge(overrides)
  end

  def stripe_subscription_payload(overrides = {})
    {
      id: "evt_#{SecureRandom.hex(8)}",
      type: "customer.subscription.created",
      data: {
        object: {
          status: "active",
          plan: { id: "plan_premium" }
        }
      }
    }.merge(overrides)
  end

  def generic_payload(overrides = {})
    {
      event: "user.created",
      data: { user_id: 123, email: "test@example.com" }
    }.merge(overrides)
  end

  def sign_github(body)
    "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", GITHUB_SECRET, body)}"
  end

  def sign_stripe(body, timestamp: Time.now.to_i)
    sig = OpenSSL::HMAC.hexdigest("SHA256", STRIPE_SECRET, "#{timestamp}.#{body}")
    "t=#{timestamp},v1=#{sig}"
  end

  def sign_generic(body)
    "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", GENERIC_SECRET, body)}"
  end

  def generate_jwt(payload = {}, secret: JWT_SECRET)
    header = Base64.urlsafe_encode64({ alg: "HS256", typ: "JWT" }.to_json).tr("=", "")
    payload_with_exp = { exp: (Time.now + 3600).to_i }.merge(payload)
    payload_b64 = Base64.urlsafe_encode64(payload_with_exp.to_json).tr("=", "")
    signing_input = "#{header}.#{payload_b64}"
    signature = Base64.urlsafe_encode64(
      OpenSSL::HMAC.digest("SHA256", secret, signing_input)
    ).tr("=", "")
    "#{header}.#{payload_b64}.#{signature}"
  end

  def auth_headers(extra = {})
    { "Authorization" => "Bearer #{generate_jwt}" }.merge(extra)
  end
end

RSpec.configure do |config|
  config.include WebhookHelpers

  config.before(:each) do
    setup_webhook_secrets
  end
end
