class CreateCreditApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_applications do |t|
      t.string :country
      t.string :full_name
      t.string :identity_document
      t.decimal :requested_amount
      t.decimal :monthly_income
      t.datetime :application_date
      t.string :status
      t.jsonb :banking_information

      t.timestamps
    end
  end
end
