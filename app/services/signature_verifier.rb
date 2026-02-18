class SignatureVerifier
  class InvalidSignature < StandardError; end

  PROVIDERS = {
    "github" => Providers::GithubProvider,
    "stripe" => Providers::StripeProvider,
    "generic" => Providers::GenericProvider
  }.freeze

  def self.verify!(provider:, raw_body:, headers:)
    provider_class = PROVIDERS[provider]
    raise InvalidSignature, "Unknown provider: #{provider}" unless provider_class

    provider_class.new.verify!(raw_body: raw_body, headers: headers)
  end

  def self.extract_metadata(provider:, raw_body:, headers:)
    provider_class = PROVIDERS[provider]
    return {} unless provider_class

    provider_class.new.extract_metadata(raw_body: raw_body, headers: headers)
  end
end
