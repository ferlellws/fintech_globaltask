module Countries
  class StrategyFactory
    STRATEGIES = {
      "ES" => Countries::EsStrategy,
      "PT" => Countries::PtStrategy,
      "IT" => Countries::ItStrategy,
      "MX" => Countries::MxStrategy,
      "CO" => Countries::CoStrategy,
      "BR" => Countries::BrStrategy
    }.freeze

    def self.for(country_code)
      strategy_class = STRATEGIES[country_code.to_s.upcase]
      raise ArgumentError, "País no soportado: #{country_code}. Países válidos: #{STRATEGIES.keys.join(', ')}" unless strategy_class
      strategy_class
    end

    COUNTRY_NAMES = {
      "ES" => "España",
      "PT" => "Portugal",
      "IT" => "Italia",
      "MX" => "México",
      "CO" => "Colombia",
      "BR" => "Brasil"
    }.freeze

    def self.supported_countries
      STRATEGIES.keys.map do |code|
        { code: code, name: COUNTRY_NAMES[code] || code }
      end
    end
  end
end
