module Countries
  class BaseStrategy
    attr_reader :application, :errors

    def initialize(application)
      @application = application
      @errors = []
    end

    # Valida el documento de identidad. Retorna true/false
    def validate_document
      raise NotImplementedError, "Subclasses must implement validate_document"
    end

    # Aplica reglas de negocio: puede modificar el estado y add errores
    def apply_business_rules
      raise NotImplementedError, "Subclasses must implement apply_business_rules"
    end

    # Llama validación + reglas. Retorna true si todo es válido
    def process
      return false unless validate_document
      apply_business_rules
      errors.empty?
    end

    protected

    def add_error(msg)
      errors << msg
    end

    def reject!
      application.status = "rejected"
    end

    def approve!
      application.status = "approved"
    end

    def manual_review!
      application.status = "manual_review"
    end

    def pending!
      application.status = "pending"
    end
  end
end
