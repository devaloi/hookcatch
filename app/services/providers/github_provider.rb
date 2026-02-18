module Providers
  class GithubProvider < BaseProvider
    SIGNATURE_HEADER = "HTTP_X_HUB_SIGNATURE_256".freeze

    def verify!(raw_body:, headers:)
      signature = headers[SIGNATURE_HEADER]
      raise SignatureVerifier::InvalidSignature, "Missing signature header" if signature.blank?

      expected = compute_hmac_sha256(secret, raw_body)
      unless secure_compare(expected, signature)
        raise SignatureVerifier::InvalidSignature, "Invalid signature"
      end
    end

    def extract_metadata(raw_body:, headers:)
      payload = JSON.parse(raw_body) rescue {}
      {
        delivery_id: headers["HTTP_X_GITHUB_DELIVERY"] || SecureRandom.uuid,
        event_type: headers["HTTP_X_GITHUB_EVENT"] || "unknown"
      }
    end

    private

    def secret
      Rails.application.config.webhook_secrets[:github]
    end
  end
end
