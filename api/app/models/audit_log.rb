class AuditLog < ApplicationRecord
  belongs_to :credit_application

  validates :new_status, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
