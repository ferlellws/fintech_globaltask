class AddAuditTriggerToCreditApplications < ActiveRecord::Migration[8.1]
  def up
    # 1. Crear la función que insertará el log de auditoría
    execute <<-SQL
      CREATE OR REPLACE FUNCTION log_credit_application_status_change()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (TG_OP = 'INSERT') THEN
          INSERT INTO audit_logs (credit_application_id, old_status, new_status, created_at, updated_at)
          VALUES (NEW.id, NULL, NEW.status, NOW(), NOW());
        ELSIF (TG_OP = 'UPDATE') THEN
          IF (OLD.status IS DISTINCT FROM NEW.status) THEN
            INSERT INTO audit_logs (credit_application_id, old_status, new_status, created_at, updated_at)
            VALUES (NEW.id, OLD.status, NEW.status, NOW(), NOW());
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # 2. Asignar el trigger a la tabla credit_applications
    execute <<-SQL
      CREATE TRIGGER trg_audit_credit_application_status
      AFTER INSERT OR UPDATE ON credit_applications
      FOR EACH ROW
      EXECUTE FUNCTION log_credit_application_status_change();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS trg_audit_credit_application_status ON credit_applications;"
    execute "DROP FUNCTION IF EXISTS log_credit_application_status_change();"
  end
end
