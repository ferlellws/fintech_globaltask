module Countries
  # Portugal: valida NIF (9 dígitos). Rechaza si ingreso mensual < 10% del monto solicitado
  class PtStrategy < BaseStrategy
    NIF_REGEXP = /\A\d{9}\z/
    INCOME_RATIO_MIN = 0.10
    MODULO_BASE = 11

    def validate_document
      doc = application.identity_document.to_s.strip
      unless doc.match?(NIF_REGEXP)
        add_error("Portugal: El NIF debe tener exactamente 9 dígitos")
        return false
      end

      # Dígito de control NIF
      unless valid_nif_checksum?(doc)
        add_error("Portugal: El NIF #{doc} tiene un dígito de control inválido")
        return false
      end

      true
    end

    def apply_business_rules
      income = application.monthly_income.to_f
      amount = application.requested_amount.to_f

      if amount > 0 && income < (amount * INCOME_RATIO_MIN)
        add_error("Portugal: El ingreso mensual debe ser al menos el 10% del monto solicitado (mínimo: #{(amount * INCOME_RATIO_MIN).round(2)})")
        reject!
      else
        approve!
      end
    end

    private

    def valid_nif_checksum?(nif)
      digits = nif.chars.map(&:to_i)
      sum = digits[0..7].each_with_index.sum { |d, i| d * (9 - i) }
      remainder = sum % MODULO_BASE
      check_digit = remainder < 2 ? 0 : MODULO_BASE - remainder
      check_digit == digits[8]
    end
  end
end
