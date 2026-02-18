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
  end
end
