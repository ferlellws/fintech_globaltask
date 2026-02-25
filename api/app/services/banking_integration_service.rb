class BankingIntegrationService
  # Simula la consulta a un servicio bancario externo por país
  # Retorna un hash con estructura diferente según el país
  MOCK_RESPONSES = {
    "ES" => ->(app) {
      {
        provider: "Banco de España Mock",
        account_verified: true,
        iban_prefix: "ES",
        credit_history_score: rand(300..850),
        annual_income_declared: (app.monthly_income * 12).to_f.round(2),
        currency: "EUR",
        verification_code: SecureRandom.hex(8),
        checked_at: Time.current.iso8601
      }
    },
    "PT" => ->(app) {
      {
        provider: "Banco de Portugal Mock",
        account_verified: true,
        iban_prefix: "PT50",
        nif_status: "active",
        monthly_obligations: (app.monthly_income * 0.15).to_f.round(2),
        currency: "EUR",
        credit_bureau: "Banco de Portugal Central de Responsabilidades",
        report_id: SecureRandom.uuid,
        checked_at: Time.current.iso8601
      }
    },
    "IT" => ->(app) {
      {
        provider: "Banca d'Italia Mock",
        account_verified: true,
        iban_prefix: "IT60",
        codice_fiscale_valid: true,
        central_risks: { total_debt: rand(0..50_000), num_loans: rand(0..5) },
        currency: "EUR",
        stability_index: rand(1..10),
        checked_at: Time.current.iso8601
      }
    },
    "MX" => ->(app) {
      {
        provider: "Central de Riesgo México Mock",
        account_verified: true,
        clabe: "#{rand(10**18..10**19 - 1)}",
        curp_valid: true,
        score_buro_mexico: rand(400..850),
        monthly_credit_obligations: (app.monthly_income * rand(0.1..0.3)).to_f.round(2),
        currency: "MXN",
        checked_at: Time.current.iso8601
      }
    },
    "CO" => ->(app) {
      {
        provider: "DataCrédito Mock",
        account_verified: true,
        cedula_valid: true,
        score_datacredito: rand(150..950),
        total_obligations: (app.monthly_income * rand(0.1..0.5)).to_f.round(2),
        currency: "COP",
        risk_category: %w[bajo medio alto].sample,
        checked_at: Time.current.iso8601
      }
    },
    "BR" => ->(app) {
      {
        provider: "Serasa Experian Brasil Mock",
        account_verified: true,
        cpf_status: "regular",
        score_serasa: rand(0..1000),
        negative_entries: rand(0..3),
        currency: "BRL",
        credit_limit_suggestion: (app.monthly_income * 5).to_f.round(2),
        checked_at: Time.current.iso8601
      }
    }
  }.freeze

  def self.fetch(credit_application)
    country = credit_application.country.to_s.upcase
    mock_fn = MOCK_RESPONSES[country]
    return { error: "No hay integración bancaria para el país: #{country}" } unless mock_fn

    mock_fn.call(credit_application)
  rescue => e
    { error: "Error al obtener información bancaria: #{e.message}", checked_at: Time.current.iso8601 }
  end
end
