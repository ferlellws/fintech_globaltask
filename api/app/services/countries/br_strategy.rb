module Countries
  # Brasil: valida CPF (11 dígitos). Score financiero simulado determina aceptación.
  class BrStrategy < BaseStrategy
    CPF_REGEXP = /\A\d{11}\z/
    MIN_SCORE_APPROVE = 700
    MIN_SCORE_REVIEW = 500

    def validate_document
      doc = application.identity_document.to_s.gsub(/\D/, "")
      unless doc.match?(CPF_REGEXP)
        add_error("Brasil: El CPF debe tener 11 dígitos")
        return false
      end

      unless valid_cpf_checksum?(doc)
        add_error("Brasil: El CPF #{doc} tiene dígitos de control inválidos")
        return false
      end

      true
    end

    def apply_business_rules
      score = mock_financial_score
      application.banking_information ||= {}
      application.banking_information = application.banking_information.merge("financial_score" => score)

      if score >= MIN_SCORE_APPROVE
        approve!
      elsif score >= MIN_SCORE_REVIEW
        manual_review!
      else
        add_error("Brasil: Score financiero (#{score}) insuficiente para procesar el crédito (mínimo: #{MIN_SCORE_REVIEW})")
        reject!
      end
    end

    private

    def mock_financial_score
      # Simulación: score basado en ingreso vs monto (escala 300-850)
      income = application.monthly_income.to_f
      amount = application.requested_amount.to_f
      return 300 if amount <= 0

      ratio = income / amount
      # ratio >= 0.1 = 850, ratio = 0.02 = 300
      score = (ratio * 5500).clamp(300, 850).round
      score
    end

    def valid_cpf_checksum?(cpf)
      return false if cpf.chars.uniq.size == 1 # Ej: "11111111111" inválido

      # Primer dígito de control
      sum = cpf[0..8].chars.each_with_index.sum { |d, i| d.to_i * (10 - i) }
      first = (sum * 10 % 11) % 10
      return false unless first == cpf[9].to_i

      # Segundo dígito de control
      sum = cpf[0..9].chars.each_with_index.sum { |d, i| d.to_i * (11 - i) }
      second = (sum * 10 % 11) % 10
      second == cpf[10].to_i
    end
  end
end
