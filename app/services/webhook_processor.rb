class WebhookProcessor
  class HandlerError < StandardError; end

  HANDLERS = {
    "github:push" => "Handlers::Github::PushHandler",
    "github:pull_request" => "Handlers::Github::PullRequestHandler",
    "stripe:payment_intent.succeeded" => "Handlers::Stripe::PaymentHandler",
    "stripe:payment_intent.payment_failed" => "Handlers::Stripe::PaymentHandler",
    "stripe:customer.subscription.created" => "Handlers::Stripe::SubscriptionHandler",
    "stripe:customer.subscription.updated" => "Handlers::Stripe::SubscriptionHandler",
    "stripe:customer.subscription.deleted" => "Handlers::Stripe::SubscriptionHandler"
  }.freeze

  def self.process(delivery)
    key = "#{delivery.provider}:#{delivery.event_type}"
    handler_class_name = HANDLERS[key]

    if handler_class_name
      handler_class_name.constantize.new.call(delivery)
    else
      Rails.logger.info("[WebhookProcessor] No handler for #{key}, marking completed")
    end
  end
end
