class ExternalNotificationJob < ApplicationJob
  queue_as :default

  def perform(credit_application_id)
    application = CreditApplication.find(credit_application_id)
    
    # Solo notificamos decisiones finales
    return unless %w[approved rejected].include?(application.status)

    Rails.logger.info "--- [NOTIFICACIÓN EXTERNA ASÍNCRONA] ---"
    Rails.logger.info "Enviando estado '#{application.status}' de la solicitud ##{application.id} a sistemas externos..."
    
    # Simulación de un hit de procesador pesado
    sleep(2) 
    
    Rails.logger.info "Estado de #{application.full_name} notificado con éxito a las centrales de riesgo."
    Rails.logger.info "----------------------------------------"
  end
end
