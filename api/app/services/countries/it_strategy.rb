module Countries
  # Italia: valida Codice Fiscale (16 alfanuméricos). Regla de estabilidad financiera:
  # ingreso mensual * 36 (3 años) debe ser >= requested_amount
  class ItStrategy < BaseStrategy
    CF_REGEXP = /\A[A-Z]{6}\d{2}[A-Z]\d{2}[A-Z]\d{3}[A-Z]\z/i
    STABILITY_MONTHS = 36

    def validate_document
      doc = application.identity_document.to_s.upcase.strip
      unless doc.match?(CF_REGEXP)
        add_error("Italia: El Codice Fiscale debe tener el formato correcto (6 letras, 2 dígitos, letra, 2 dígitos, letra, 3 dígitos, letra)")
        return false
      end
      true
    end

    def apply_business_rules
      income = application.monthly_income.to_f
      amount = application.requested_amount.to_f
      projected_income = income * STABILITY_MONTHS

      if projected_income >= amount
        approve!
      elsif projected_income >= amount * 0.7
        manual_review!
      else
        add_error("Italia: El ingreso proyectado a 36 meses (#{projected_income.round(2)}) es insuficiente para el monto solicitado (#{amount})")
        reject!
      end
    end
  end
end
