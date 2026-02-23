class AddIndexesToCreditApplications < ActiveRecord::Migration[8.1]
  def change
    add_index :credit_applications, :country
    add_index :credit_applications, :status
    add_index :credit_applications, :application_date
    add_index :credit_applications, [ :country, :status ], name: "idx_credit_apps_country_status"
    add_index :credit_applications, :created_at
    add_index :credit_applications, :banking_information, using: :gin
    add_index :users, :email, unique: true
  end
end


