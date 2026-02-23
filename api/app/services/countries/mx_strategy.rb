module Countries
  # México: valida CURP (18 alfanuméricos). Ratio: mensualidad estimada no debe superar 40% del ingreso mensual
  # Mensualidad estimada = requested_amount / 24 meses
  class MxStrategy < BaseStrategy
    CURP_REGEXP = /\A[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z\d]\d\z/i
    TERM_MONTHS = 24
    MAX_PAYMENT_RATIO = 0.40

    def validate_document
      doc = application.identity_document.to_s.upcase.strip
      unless doc.match?(CURP_REGEXP)
        add_error("México: El CURP debe tener 18 caracteres con el formato correcto")
        return false
      end
      true
    end

    def apply_business_rules
      income = application.monthly_income.to_f
      amount = application.requested_amount.to_f
      estimated_payment = amount / TERM_MONTHS
      max_allowed = income * MAX_PAYMENT_RATIO

      if income <= 0
        add_error("México: El ingreso mensual debe ser mayor a 0")
        reject!
      elsif estimated_payment > max_allowed
        add_error("México: La mensualidad estimada (#{estimated_payment.round(2)}) supera el 40% del ingreso mensual permitido (#{max_allowed.round(2)})")
        reject!
      elsif estimated_payment > max_allowed * 0.8
        manual_review!
      else
        pending!
      end
    end
  end
end
