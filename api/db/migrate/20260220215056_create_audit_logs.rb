class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :credit_application, null: false, foreign_key: true
      t.string :old_status
      t.string :new_status

      t.timestamps
    end
  end
end
