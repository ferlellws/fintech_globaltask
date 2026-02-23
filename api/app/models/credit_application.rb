class CreditApplication < ApplicationRecord
  belongs_to :user, optional: true
  has_many :audit_logs, dependent: :destroy

  VALID_STATUSES = %w[pending approved rejected manual_review under_review].freeze
  VALID_COUNTRIES = Countries::StrategyFactory::STRATEGIES.keys.freeze

  validates :country, presence: true, inclusion: { in: VALID_COUNTRIES, message: "%{value} no es un país soportado" }
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :identity_document, presence: true
  validates :requested_amount, presence: true, numericality: { greater_than: 0 }
  validates :monthly_income, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: VALID_STATUSES }
  validate :document_format_by_country

  before_validation :set_defaults, on: :create
  after_create_commit :enqueue_risk_evaluation
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

  scope :by_country, ->(country) { where(country: country) if country.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  def apply_country_strategy!
    strategy_class = Countries::StrategyFactory.for(country)
    strategy = strategy_class.new(self)

    if strategy.process
      true
    else
      errors.add(:base, strategy.errors.join(", "))
      false
    end
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.application_date ||= Time.current
  end

  def document_format_by_country
    return if country.blank? || identity_document.blank?
    return unless VALID_COUNTRIES.include?(country)

    strategy_class = Countries::StrategyFactory.for(country)
    strategy = strategy_class.new(self)
    
    unless strategy.validate_document
      strategy.errors.each { |err| errors.add(:base, err) }
    end
  end

  def enqueue_risk_evaluation
    RiskEvaluationJob.perform_later(id)
  end

  def broadcast_status_change
    ActionCable.server.broadcast(
      "credit_applications",
      {
        type: "status_changed",
        id: id,
        status: status,
        status_name: I18n.t("credit_applications.statuses.#{status}"),
        country: country,
        full_name: full_name,
        updated_at: updated_at.iso8601
      }
    )
  end
end
