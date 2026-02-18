class ProcessWebhookJob < ApplicationJob
  queue_as :default

  BACKOFF_SCHEDULE = [ 30, 120, 600 ].freeze

  def perform(delivery_id)
    delivery = WebhookDelivery.find(delivery_id)
    return if delivery.completed? || delivery.dead?

    delivery.update!(status: :processing, attempts: delivery.attempts + 1)

    WebhookProcessor.process(delivery)

    delivery.update!(status: :completed, processed_at: Time.current)
  rescue WebhookProcessor::HandlerError => e
    handle_failure(delivery, e)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    handle_failure(delivery, e)
  rescue RuntimeError => e
    handle_failure(delivery, e)
  end

  private

  def handle_failure(delivery, error)
    return unless delivery

    if delivery.attempts >= WebhookDelivery::MAX_ATTEMPTS
      move_to_dead_letter(delivery, error)
    else
      delivery.update!(
        status: :failed,
        error_message: "#{error.class}: #{error.message} (delivery=#{delivery.id}, provider=#{delivery.provider})"
      )
      backoff = BACKOFF_SCHEDULE.fetch(delivery.attempts - 1, BACKOFF_SCHEDULE.last)
      self.class.set(wait: backoff.seconds).perform_later(delivery.id)
    end
  end

  def move_to_dead_letter(delivery, error)
    DeadLetter.create!(
      webhook_delivery: delivery,
      error_class: error.class.name,
      error_message: error.message,
      backtrace: error.backtrace&.first(HookCatch::BACKTRACE_LIMIT)&.join("\n"),
      failed_at: Time.current
    )
    delivery.update!(
      status: :dead,
      error_message: "#{error.class}: #{error.message} (delivery=#{delivery.id}, provider=#{delivery.provider})"
    )
  end
end
