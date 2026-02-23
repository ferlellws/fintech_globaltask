class RiskEvaluationJob < ApplicationJob
  queue_as :default

  def perform(credit_application_id)
    application = CreditApplication.find(credit_application_id)

    # Solo procesar si está en estado pendiente
    return unless application.status == "pending"

    # Obtener información bancaria mock
    banking_info = BankingIntegrationService.fetch(application)
    application.banking_information = banking_info

    # Aplicar estrategia del país para determinar estado final
    application.apply_country_strategy!

    # Guardar cambios de banking_information y status
    application.save! if application.changed?

    Rails.logger.info("RiskEvaluationJob: Application ##{credit_application_id} evaluated. Status: #{application.status}")
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("RiskEvaluationJob: CreditApplication ##{credit_application_id} not found")
  rescue => e
    Rails.logger.error("RiskEvaluationJob error for ##{credit_application_id}: #{e.message}")
    raise # Re-raise para que Solid Queue pueda reintentar
  end
end
