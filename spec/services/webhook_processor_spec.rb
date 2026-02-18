require "rails_helper"

RSpec.describe WebhookProcessor do
  describe ".process" do
    it "routes github:push to PushHandler" do
      delivery = create(:webhook_delivery, provider: "github", event_type: "push")
      handler = instance_double("Handlers::Github::PushHandler")
      allow(Handlers::Github::PushHandler).to receive(:new).and_return(handler)
      allow(handler).to receive(:call)

      described_class.process(delivery)

      expect(handler).to have_received(:call).with(delivery)
    end

    it "routes github:pull_request to PullRequestHandler" do
      delivery = create(:webhook_delivery, provider: "github", event_type: "pull_request",
        payload: { action: "opened", pull_request: { number: 1, title: "Test" } })
      handler = instance_double("Handlers::Github::PullRequestHandler")
      allow(Handlers::Github::PullRequestHandler).to receive(:new).and_return(handler)
      allow(handler).to receive(:call)

      described_class.process(delivery)

      expect(handler).to have_received(:call).with(delivery)
    end

    it "routes stripe:payment_intent.succeeded to PaymentHandler" do
      delivery = create(:webhook_delivery, :stripe, event_type: "payment_intent.succeeded")
      handler = instance_double("Handlers::Stripe::PaymentHandler")
      allow(Handlers::Stripe::PaymentHandler).to receive(:new).and_return(handler)
      allow(handler).to receive(:call)

      described_class.process(delivery)

      expect(handler).to have_received(:call).with(delivery)
    end

    it "handles unknown events gracefully" do
      delivery = create(:webhook_delivery, provider: "github", event_type: "unknown_event")
      expect {
        described_class.process(delivery)
      }.not_to raise_error
    end
  end
end
