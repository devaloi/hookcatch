module Providers
  class GenericProvider < BaseProvider
    SIGNATURE_HEADER = "HTTP_X_SIGNATURE_256".freeze

    def verify!(raw_body:, headers:)
      signature = headers[SIGNATURE_HEADER]
      raise SignatureVerifier::InvalidSignature, "Missing signature header" if signature.blank?

      expected = compute_hmac_sha256(secret, raw_body)
      unless secure_compare(expected, signature)
        raise SignatureVerifier::InvalidSignature, "Invalid signature"
      end
    end

    def extract_metadata(raw_body:, headers:)
      payload = parse_json_body(raw_body)
      {
        delivery_id: headers["HTTP_X_DELIVERY_ID"] || SecureRandom.uuid,
        event_type: payload["event"] || payload["type"] || "unknown"
      }
    end

    private

    def secret
      Rails.application.config.webhook_secrets[:generic]
    end
  end
end
