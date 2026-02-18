module Providers
  class BaseProvider
    def verify!(raw_body:, headers:)
      raise NotImplementedError
    end

    def extract_metadata(raw_body:, headers:)
      raise NotImplementedError
    end

    private

    def secret
      raise NotImplementedError
    end

    def secure_compare(a, b)
      ActiveSupport::SecurityUtils.secure_compare(a.to_s, b.to_s)
    end

    def compute_hmac_sha256(secret, data)
      "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, data)}"
    end

    def extract_relevant_headers(request_headers, prefix_patterns)
      request_headers.select { |k, _| prefix_patterns.any? { |p| k.start_with?(p) } }
    end

    def parse_json_body(raw_body)
      JSON.parse(raw_body)
    rescue JSON::ParserError => e
      Rails.logger.warn("[#{self.class.name}] Failed to parse JSON body: #{e.message}")
      {}
    end
  end
end
