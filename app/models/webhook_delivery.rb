class WebhookDelivery < ApplicationRecord
  include Paginatable

  has_one :dead_letter, dependent: :destroy

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3, dead: 4 }

  validates :provider, presence: true
  validates :delivery_id, presence: true, uniqueness: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :failed_deliveries, -> { where(status: :failed) }
  scope :pending_deliveries, -> { where(status: :pending) }

  MAX_ATTEMPTS = 3
end
