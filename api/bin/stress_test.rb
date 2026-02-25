# Script de generación de solicitudes aleatorias para sustentación
# Ejecución: bin/rails runner bin/stress_test.rb [cantidad]

count = (ARGV[0] || 5).to_i
first_names = ["Juan", "Maria", "Carlos", "Ana", "Luis", "Elena", "Pedro", "Lucia"]
last_names = ["Garcia", "Rodriguez", "Lopez", "Martinez", "Gonzalez", "Perez"]

user = User.first || User.create!(email: "demo@example.com", password: "password123", full_name: "Demo User")

def generate_pt_nif
  base = "5" + 7.times.map { rand(10) }.join
  digits = base.chars.map(&:to_i)
  sum = digits.each_with_index.sum { |d, i| d * (9 - i) }
  remainder = sum % 11
  check_digit = remainder < 2 ? 0 : 11 - remainder
  base + check_digit.to_s
end

def generate_es_dni
  number = rand(10**7..10**8-1)
  letters = "TRWAGMYFPDXBNJZSQVHLCKE"
  number.to_s + letters[number % 23]
end

def generate_it_cf
  letters = ("A".."Z").to_a
  digits = (0..9).to_a
  "#{letters.sample(6).join}#{digits.sample(2).join}#{letters.sample}#{digits.sample(2).join}#{letters.sample}#{digits.sample(3).join}#{letters.sample}"
end

def generate_br_cpf
  base = 9.times.map { rand(10) }
  # Primer dígito
  sum = base.each_with_index.sum { |d, i| d * (10 - i) }
  d1 = (sum * 10 % 11) % 10
  # Segundo dígito
  base_with_d1 = base + [d1]
  sum = base_with_d1.each_with_index.sum { |d, i| d * (11 - i) }
  d2 = (sum * 10 % 11) % 10
  (base + [d1, d2]).join
end

puts "🚀 Iniciando generación de #{count} solicitudes concurrentes..."

count.times do |i|
  country = ["CO", "MX", "PT", "ES", "IT", "BR"].sample
  full_name = "#{first_names.sample} #{last_names.sample}"
  
  document = case country
             when "PT" then generate_pt_nif
             when "ES" then generate_es_dni
             when "IT" then generate_it_cf
             when "BR" then generate_br_cpf
             when "MX" 
               letters = ("A".."Z").to_a
               digits = (0..9).to_a
               "#{letters.sample(4).join}#{digits.sample(6).join}#{['H','M'].sample}#{letters.sample(5).join}#{letters.sample}#{digits.sample}"
             else rand(10**8..10**9-1).to_s
             end

  # Aleatorizar el tipo de caso: 0=Aprobado, 1=Revisión Manual, 2=Rechazado
  case_type = rand(0..2)
  
  case country
  when "ES"
    if case_type == 1 # Revisión Manual
      amount = rand(51000..60000)
      income = rand(5000..10000)
    elsif case_type == 2 # Rechazado
      amount = rand(10000..30000)
      income = 500
    else # Aprobado
      amount = rand(1000..45000)
      income = rand(3000..10000)
    end
  when "CO"
    if case_type == 1 # Revisión Manual
      amount = 25000
      income = 2000
    elsif case_type == 2 # Rechazado
      amount = 40000
      income = 2000
    else # Aprobado
      amount = rand(1000..15000)
      income = rand(5000..10000)
    end
  when "MX"
    if case_type == 1 # Revisión Manual
      amount = 40000
      income = 5000
    elsif case_type == 2 # Rechazado
      amount = 60000
      income = 5000
    else # Aprobado
      amount = rand(1000..20000)
      income = rand(6000..12000)
    end
  when "IT"
    if case_type == 1 # Revisión Manual (70%-100% ingresos 36 meses)
      amount = 36000
      income = 800 # 800 * 36 = 28800 (80% de 36000)
    elsif case_type == 2 # Rechazado
      amount = 50000
      income = 500 # 500 * 36 = 18000 (muy bajo)
    else # Aprobado
      amount = 10000
      income = 2000
    end
  when "BR"
    if case_type == 1 # Revisión Manual (Score 500-700)
      amount = 20000
      income = 2000 # Ratio = 0.1 -> score ~ 550
    elsif case_type == 2 # Rechazado
      amount = 50000
      income = 1000 # Ratio = 0.02 -> score ~ 300
    else # Aprobado
      amount = 5000
      income = 10000 # Ratio alto -> score ~ 850
    end
  else # PT
    amount = rand(1000..30000)
    income = case_type == 2 ? 500 : (amount * 0.20)
  end

  app = CreditApplication.new(
    user: user,
    country: country,
    full_name: full_name,
    identity_document: document,
    requested_amount: amount,
    monthly_income: income
  )

  if app.save
    puts "✅ [#{i+1}/#{count}] Solicitud ##{app.id} creada para #{full_name} (#{country})"
  else
    puts "❌ [#{i+1}/#{count}] Error al crear para #{full_name}: #{app.errors.full_messages.join(', ')}"
  end
end

puts "✨ Proceso completado. Revisa tus terminales de 'bin/jobs' para ver el procesamiento paralelo."
