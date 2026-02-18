module Handlers
  module Stripe
    class PaymentHandler < BaseHandler
      def call(delivery)
        payload = delivery.payload
        data = payload.dig("data", "object") || {}
        amount = data["amount"]
        currency = data["currency"]
        status = data["status"]

        Rails.logger.info(
          "[Stripe::Payment] #{amount} #{currency&.upcase} — #{status}"
        )
      end
    end
  end
end
