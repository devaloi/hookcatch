class ApplicationController < ActionController::API
  before_action :authenticate_jwt!

  private

  def authenticate_jwt!
    token = request.headers["Authorization"]&.sub(/^Bearer /, "")
    unless token.present? && valid_jwt?(token)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def valid_jwt?(token)
    secret = Rails.application.config.jwt_secret
    return false if secret.blank?

    parts = token.split(".")
    return false unless parts.length == 3

    header_b64, payload_b64, signature_b64 = parts

    # Verify signature
    signing_input = "#{header_b64}.#{payload_b64}"
    expected_sig = Base64.urlsafe_encode64(
      OpenSSL::HMAC.digest("SHA256", secret, signing_input)
    ).tr("=", "")

    return false unless ActiveSupport::SecurityUtils.secure_compare(expected_sig, signature_b64)

    # Check expiration
    payload = JSON.parse(Base64.urlsafe_decode64(payload_b64))
    return false if payload["exp"] && Time.now.to_i > payload["exp"]

    true
  rescue StandardError
    false
  end

  def pagination_meta(collection)
    {
      current_page: collection.respond_to?(:current_page) ? collection.current_page : 1,
      total_count: collection.respond_to?(:total_count) ? collection.total_count : collection.size
    }
  end
end

