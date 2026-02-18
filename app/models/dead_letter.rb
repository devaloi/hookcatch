class DeadLetter < ApplicationRecord
  belongs_to :webhook_delivery

  validates :error_class, presence: true
  validates :failed_at, presence: true
end
