require "rails_helper"

RSpec.describe DeadLetter, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      dead_letter = build(:dead_letter)
      expect(dead_letter).to be_valid
    end

    it "requires error_class" do
      dead_letter = build(:dead_letter, error_class: nil)
      expect(dead_letter).not_to be_valid
    end

    it "requires failed_at" do
      dead_letter = build(:dead_letter, failed_at: nil)
      expect(dead_letter).not_to be_valid
    end

    it "requires webhook_delivery" do
      dead_letter = build(:dead_letter, webhook_delivery: nil)
      expect(dead_letter).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to webhook_delivery" do
      delivery = create(:webhook_delivery, :dead)
      dead_letter = create(:dead_letter, webhook_delivery: delivery)
      expect(dead_letter.webhook_delivery).to eq(delivery)
    end
  end
end
