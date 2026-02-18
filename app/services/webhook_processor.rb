class WebhookProcessor
  class HandlerError < StandardError; end

  HANDLER_MAP = {
    "github:push" => Handlers::Github::PushHandler,
    "github:pull_request" => Handlers::Github::PullRequestHandler,
    "stripe:payment_intent.succeeded" => Handlers::Stripe::PaymentHandler,
    "stripe:payment_intent.payment_failed" => Handlers::Stripe::PaymentHandler,
    "stripe:customer.subscription.created" => Handlers::Stripe::SubscriptionHandler,
    "stripe:customer.subscription.updated" => Handlers::Stripe::SubscriptionHandler,
    "stripe:customer.subscription.deleted" => Handlers::Stripe::SubscriptionHandler
  }.freeze

  def self.process(delivery)
    key = "#{delivery.provider}:#{delivery.event_type}"
    handler_class = HANDLER_MAP[key]

    if handler_class
      handler_class.new.call(delivery)
    else
      Rails.logger.info("[WebhookProcessor] No handler for #{key} (delivery=#{delivery.id}), marking completed")
    end
  end
end
