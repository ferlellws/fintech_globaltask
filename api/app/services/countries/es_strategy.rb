module Countries
  # España: valida DNI (8 dígitos + letra). Si monto > 50000 → revisión manual
  class EsStrategy < BaseStrategy
    DNI_REGEXP = /\A\d{8}[A-Z]\z/
    DNI_LETTERS = "TRWAGMYFPDXBNJZSQVHLCKE"
    MANUAL_REVIEW_THRESHOLD = 50_000

    def validate_document
      doc = application.identity_document.to_s.upcase.strip
      unless doc.match?(DNI_REGEXP)
        add_error("España: El DNI debe tener 8 dígitos seguidos de una letra (ej: 12345678A)")
        return false
      end

      # Validar la letra de control
      number = doc[0..7].to_i
      expected_letter = DNI_LETTERS[number % 23]
      unless doc[-1] == expected_letter
        add_error("España: La letra del DNI #{doc} es incorrecta. Debería ser #{expected_letter}")
        return false
      end

      true
    end

    def apply_business_rules
      if application.requested_amount > MANUAL_REVIEW_THRESHOLD
        manual_review!
      else
        pending!
      end
    end
  end
end
