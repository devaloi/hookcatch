module Handlers
  module Stripe
    class SubscriptionHandler < BaseHandler
      def call(delivery)
        payload = delivery.payload
        data = payload.dig("data", "object") || {}
        plan = data.dig("plan", "id") || data.dig("items", "data", 0, "plan", "id")
        status = data["status"]

        Rails.logger.info(
          "[Stripe::Subscription] plan=#{plan} status=#{status}"
        )
      end
    end
  end
end
