class WebhooksController < ApplicationController
  skip_before_action :authenticate_jwt!, only: :receive
  before_action :set_raw_body, only: :receive

  # POST /webhooks/:provider
  def receive
    provider = params[:provider]

    unless SignatureVerifier::PROVIDERS.key?(provider)
      return render json: { error: "Unknown provider: #{provider}" }, status: :not_found
    end

    http_headers = extract_relevant_headers(request)

    SignatureVerifier.verify!(
      provider: provider,
      raw_body: @raw_body,
      headers: http_headers
    )

    metadata = SignatureVerifier.extract_metadata(
      provider: provider,
      raw_body: @raw_body,
      headers: http_headers
    )

    # Idempotency check
    existing = WebhookDelivery.find_by(delivery_id: metadata[:delivery_id])
    if existing
      return render json: { status: "duplicate", delivery_id: metadata[:delivery_id] }, status: :ok
    end

    delivery = WebhookDelivery.create!(
      provider: provider,
      delivery_id: metadata[:delivery_id],
      event_type: metadata[:event_type],
      payload: JSON.parse(@raw_body),
      headers: http_headers,
      status: :pending
    )

    ProcessWebhookJob.perform_later(delivery.id)

    render json: { status: "accepted", delivery_id: delivery.delivery_id }, status: :ok
  rescue SignatureVerifier::InvalidSignature => e
    render json: { error: e.message }, status: :unauthorized
  rescue JSON::ParserError
    render json: { error: "Invalid JSON payload" }, status: :bad_request
  end

  # GET /webhooks/deliveries
  def index
    deliveries = WebhookDelivery.recent
    deliveries = deliveries.by_provider(params[:provider]) if params[:provider].present?
    deliveries = deliveries.where(status: params[:status]) if params[:status].present?
    deliveries = deliveries.page(params[:page])

    render json: {
      deliveries: deliveries.map { |d| delivery_json(d) },
      meta: pagination_meta(deliveries)
    }
  end

  # GET /webhooks/deliveries/:id
  def show
    delivery = WebhookDelivery.find(params[:id])
    render json: delivery_json(delivery, include_payload: true)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Delivery not found (id=#{params[:id]})" }, status: :not_found
  end

  # POST /webhooks/deliveries/:id/replay
  def replay
    delivery = WebhookDelivery.find(params[:id])
    delivery.update!(status: :pending, attempts: 0, error_message: nil)
    ProcessWebhookJob.perform_later(delivery.id)

    render json: { status: "replayed", delivery_id: delivery.delivery_id }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Delivery not found (id=#{params[:id]})" }, status: :not_found
  end

  # GET /webhooks/dead_letters
  def dead_letters
    letters = DeadLetter.includes(:webhook_delivery)
                        .order(failed_at: :desc)
                        .page(params[:page])

    render json: {
      dead_letters: letters.map { |dl| dead_letter_json(dl) },
      meta: pagination_meta(letters)
    }
  end

  private

  def set_raw_body
    @raw_body = request.body.read
    request.body.rewind
  end

  def extract_relevant_headers(request)
    request.headers.env.select { |k, _| k.start_with?("HTTP_") }
  end

  def delivery_json(delivery, include_payload: false)
    json = {
      id: delivery.id,
      provider: delivery.provider,
      delivery_id: delivery.delivery_id,
      event_type: delivery.event_type,
      status: delivery.status,
      attempts: delivery.attempts,
      error_message: delivery.error_message,
      processed_at: delivery.processed_at,
      created_at: delivery.created_at
    }
    json[:payload] = delivery.payload if include_payload
    json[:headers] = delivery.headers if include_payload
    json
  end

  def dead_letter_json(dl)
    {
      id: dl.id,
      webhook_delivery_id: dl.webhook_delivery_id,
      error_class: dl.error_class,
      error_message: dl.error_message,
      backtrace: dl.backtrace,
      failed_at: dl.failed_at,
      delivery: delivery_json(dl.webhook_delivery)
    }
  end
end
