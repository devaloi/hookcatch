module Providers
  class StripeProvider < BaseProvider
    SIGNATURE_HEADER = "HTTP_STRIPE_SIGNATURE".freeze
    TIMESTAMP_TOLERANCE = 300 # 5 minutes

    def verify!(raw_body:, headers:)
      sig_header = headers[SIGNATURE_HEADER]
      raise SignatureVerifier::InvalidSignature, "Missing signature header" if sig_header.blank?

      elements = parse_signature_header(sig_header)
      timestamp = elements["t"]
      signatures = elements["v1"]

      raise SignatureVerifier::InvalidSignature, "Invalid signature format" if timestamp.blank? || signatures.blank?

      # Check timestamp tolerance — Integer() raises ArgumentError for invalid input
      begin
        ts = Integer(timestamp)
      rescue ArgumentError
        raise SignatureVerifier::InvalidSignature, "Invalid timestamp format"
      end

      if (Time.now.to_i - ts).abs > TIMESTAMP_TOLERANCE
        raise SignatureVerifier::InvalidSignature, "Timestamp outside tolerance"
      end

      signed_payload = "#{timestamp}.#{raw_body}"
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

      unless secure_compare(expected, signatures)
        raise SignatureVerifier::InvalidSignature, "Invalid signature"
      end
    end

    def extract_metadata(raw_body:, headers:)
      payload = parse_json_body(raw_body)
      {
        delivery_id: payload["id"] || SecureRandom.uuid,
        event_type: payload["type"] || "unknown"
      }
    end

    private

    def secret
      Rails.application.config.webhook_secrets[:stripe]
    end

    def parse_signature_header(header)
      header.split(",").each_with_object({}) do |item, hash|
        key, value = item.strip.split("=", 2)
        hash[key] = value
      end
    end
  end
end
