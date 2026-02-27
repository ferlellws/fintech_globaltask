class CreditApplication < ApplicationRecord
  belongs_to :user, optional: true
  has_many :audit_logs, dependent: :destroy

  VALID_STATUSES = %w[pending approved rejected manual_review].freeze
  VALID_COUNTRIES = Countries::StrategyFactory::STRATEGIES.keys.freeze

  validates :country, presence: true, inclusion: { in: VALID_COUNTRIES, message: "%{value} no es un país soportado" }
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :identity_document, presence: true
  validates :requested_amount, presence: true, numericality: { greater_than: 0 }
  validates :monthly_income, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: VALID_STATUSES }
  validate :document_format_by_country

  before_validation :set_defaults, on: :create
  after_create_commit :broadcast_creation
  after_create_commit :enqueue_risk_evaluation
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?
  after_update_commit :enqueue_notification, if: :saved_change_to_status?

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

  def translated_banking_information
    return nil if banking_information.nil?

    banking_information.each_with_object({}) do |(key, value), hash|
      translated_key = I18n.t("banking_info.labels.#{key}", default: key.to_s.humanize)
      translated_value = case value
                        when true, false
                          I18n.t("banking_info.values.#{value}")
                        when String
                          if value.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
                            begin
                              Time.zone.parse(value).strftime("%d/%m/%Y %I:%M %p")
                            rescue
                              I18n.t("banking_info.values.#{value.downcase}", default: value)
                            end
                          else
                            I18n.t("banking_info.values.#{value.downcase}", default: value)
                          end
                        when Hash
                          value.map { |k, v| "#{I18n.t("banking_info.labels.#{k}", default: k.to_s.humanize)}: #{v}" }.join(", ")
                        else
                          value
                        end
      hash[translated_key] = translated_value
    end
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
        country_name: Countries::StrategyFactory::COUNTRY_NAMES[country] || country,
        full_name: full_name,
        updated_at: updated_at.iso8601,
        banking_information: translated_banking_information,
        audit_logs: audit_logs.recent.map { |l| {
          old_status: l.old_status,
          old_status_name: l.old_status ? I18n.t("credit_applications.statuses.#{l.old_status}") : nil,
          new_status: l.new_status,
          new_status_name: I18n.t("credit_applications.statuses.#{l.new_status}"),
          changed_at: l.created_at
        }}
      }
    )
  end

  def broadcast_creation
    ActionCable.server.broadcast(
      "credit_applications",
      {
        type: "application_created",
        id: id,
        full_name: full_name,
        identity_document: identity_document,
        country: country,
        country_name: Countries::StrategyFactory::COUNTRY_NAMES[country] || country,
        requested_amount: requested_amount,
        status: status,
        status_name: I18n.t("credit_applications.statuses.#{status}"),
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601
      }
    )
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

  def enqueue_notification
    ExternalNotificationJob.perform_later(id)
  end
end
