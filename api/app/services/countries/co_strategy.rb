module Countries
  # Colombia: valida Cédula de Ciudadanía (CC, 5-10 dígitos).
  # Ratio deuda/ingreso: la deuda total simulada no debe superar 50% del ingreso mensual
  class CoStrategy < BaseStrategy
    CC_REGEXP = /\A\d{5,10}\z/
    MAX_DEBT_RATIO = 0.50
    # Simulación: deuda equivale al 30% del monto solicitado como deuda mensual
    MOCK_DEBT_RATIO = 0.03

    def validate_document
      doc = application.identity_document.to_s.strip
      unless doc.match?(CC_REGEXP)
        add_error("Colombia: La Cédula de Ciudadanía debe tener entre 5 y 10 dígitos")
        return false
      end
      true
    end

    def apply_business_rules
      income = application.monthly_income.to_f
      amount = application.requested_amount.to_f
      # Deuda mensual simulada (servicio de deuda del crédito solicitado)
      mock_monthly_debt = amount * MOCK_DEBT_RATIO

      if income <= 0
        add_error("Colombia: El ingreso mensual debe ser mayor a 0")
        reject!
      elsif mock_monthly_debt > income * MAX_DEBT_RATIO
        add_error("Colombia: La carga de deuda estimada (#{mock_monthly_debt.round(2)}) supera el 50% del ingreso mensual (#{income})")
        reject!
      elsif mock_monthly_debt > income * 0.35
        manual_review!
      else
        approve!
      end
    end
  end
end
