require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  describe "validations" do
    subject { build(:webhook_delivery) }

    it { is_expected.to be_valid }

    it "requires provider" do
      subject.provider = nil
      expect(subject).not_to be_valid
    end

    it "requires delivery_id" do
      subject.delivery_id = nil
      expect(subject).not_to be_valid
    end

    it "requires unique delivery_id" do
      create(:webhook_delivery, delivery_id: "dup-123")
      subject.delivery_id = "dup-123"
      expect(subject).not_to be_valid
    end
  end

  describe "enums" do
    it "defines status enum" do
      expect(described_class.statuses).to eq(
        "pending" => 0, "processing" => 1, "completed" => 2, "failed" => 3, "dead" => 4
      )
    end
  end

  describe "scopes" do
    before do
      create(:webhook_delivery, provider: "github", status: :completed, created_at: 2.days.ago)
      create(:webhook_delivery, provider: "stripe", status: :failed, created_at: 1.day.ago)
      create(:webhook_delivery, provider: "github", status: :pending, created_at: Time.current)
    end

    it ".recent orders by created_at desc" do
      deliveries = described_class.recent
      expect(deliveries.first.created_at).to be > deliveries.last.created_at
    end

    it ".by_provider filters by provider" do
      expect(described_class.by_provider("github").count).to eq(2)
      expect(described_class.by_provider("stripe").count).to eq(1)
    end

    it ".failed_deliveries returns failed records" do
      expect(described_class.failed_deliveries.count).to eq(1)
    end

    it ".pending_deliveries returns pending records" do
      expect(described_class.pending_deliveries.count).to eq(1)
    end
  end

  describe "associations" do
    it "has one dead_letter" do
      delivery = create(:webhook_delivery, :dead)
      dead_letter = create(:dead_letter, webhook_delivery: delivery)
      expect(delivery.dead_letter).to eq(dead_letter)
    end

    it "destroys dead_letter on destroy" do
      delivery = create(:webhook_delivery, :dead)
      create(:dead_letter, webhook_delivery: delivery)
      expect { delivery.destroy }.to change(DeadLetter, :count).by(-1)
    end
  end

  describe "status transitions" do
    let(:delivery) { create(:webhook_delivery) }

    it "starts as pending" do
      expect(delivery).to be_pending
    end

    it "can transition to processing" do
      delivery.processing!
      expect(delivery).to be_processing
    end

    it "can transition to completed" do
      delivery.completed!
      expect(delivery).to be_completed
    end

    it "can transition to failed" do
      delivery.failed!
      expect(delivery).to be_failed
    end

    it "can transition to dead" do
      delivery.dead!
      expect(delivery).to be_dead
    end
  end

  describe "defaults" do
    let(:delivery) { create(:webhook_delivery) }

    it "defaults attempts to 0" do
      expect(delivery.attempts).to eq(0)
    end

    it "defaults status to pending" do
      expect(delivery.status).to eq("pending")
    end
  end
end
