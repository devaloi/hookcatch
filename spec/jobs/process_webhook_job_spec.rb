require "rails_helper"

RSpec.describe ProcessWebhookJob, type: :job do
  describe "#perform" do
    context "successful processing" do
      it "marks delivery as completed" do
        delivery = create(:webhook_delivery, status: :pending)
        allow(WebhookProcessor).to receive(:process)

        described_class.new.perform(delivery.id)

        delivery.reload
        expect(delivery.status).to eq("completed")
        expect(delivery.processed_at).to be_present
        expect(delivery.attempts).to eq(1)
      end
    end

    context "when processing fails" do
      it "marks delivery as failed and retries" do
        delivery = create(:webhook_delivery, status: :pending, attempts: 0)
        allow(WebhookProcessor).to receive(:process).and_raise(RuntimeError, "boom")

        described_class.new.perform(delivery.id)

        delivery.reload
        expect(delivery.status).to eq("failed")
        expect(delivery.attempts).to eq(1)
        expect(delivery.error_message).to include("boom")
      end

      it "creates dead letter after max attempts" do
        delivery = create(:webhook_delivery, status: :pending, attempts: 2)
        allow(WebhookProcessor).to receive(:process).and_raise(RuntimeError, "fatal")

        expect {
          described_class.new.perform(delivery.id)
        }.to change(DeadLetter, :count).by(1)

        delivery.reload
        expect(delivery.status).to eq("dead")
        expect(delivery.attempts).to eq(3)
      end
    end

    context "when delivery is already completed" do
      it "skips processing" do
        delivery = create(:webhook_delivery, :completed)
        expect(WebhookProcessor).not_to receive(:process)

        described_class.new.perform(delivery.id)
      end
    end

    context "when delivery is already dead" do
      it "skips processing" do
        delivery = create(:webhook_delivery, :dead)
        expect(WebhookProcessor).not_to receive(:process)

        described_class.new.perform(delivery.id)
      end
    end
  end
end
