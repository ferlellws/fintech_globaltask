class AddStatusTriggerToCreditApplications < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION log_credit_application_status_change()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
          INSERT INTO audit_logs (credit_application_id, old_status, new_status, created_at, updated_at)
          VALUES (NEW.id, OLD.status, NEW.status, NOW(), NOW());
        ELSIF (TG_OP = 'INSERT' AND NEW.status IS NOT NULL) THEN
          INSERT INTO audit_logs (credit_application_id, old_status, new_status, created_at, updated_at)
          VALUES (NEW.id, NULL, NEW.status, NOW(), NOW());
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER credit_application_status_trigger
      AFTER INSERT OR UPDATE ON credit_applications
      FOR EACH ROW
      EXECUTE FUNCTION log_credit_application_status_change();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS credit_application_status_trigger ON credit_applications;
      DROP FUNCTION IF EXISTS log_credit_application_status_change();
    SQL
  end
end
