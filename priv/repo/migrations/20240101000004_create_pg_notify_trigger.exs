defmodule CreditApp.Repo.Migrations.CreatePgNotifyTrigger do
  use Ecto.Migration

  def up do
    # PostgreSQL function that sends NOTIFY on credit_application changes
    execute """
    CREATE OR REPLACE FUNCTION notify_credit_application_changes()
    RETURNS trigger AS $$
    DECLARE
      payload TEXT;
    BEGIN
      payload := json_build_object(
        'operation', TG_OP,
        'id', NEW.id,
        'country', NEW.country,
        'status', NEW.status
      )::text;

      PERFORM pg_notify('credit_application_changes', payload);
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Trigger on INSERT
    execute """
    CREATE TRIGGER credit_application_insert_trigger
    AFTER INSERT ON credit_applications
    FOR EACH ROW
    EXECUTE FUNCTION notify_credit_application_changes();
    """

    # Trigger on UPDATE
    execute """
    CREATE TRIGGER credit_application_update_trigger
    AFTER UPDATE ON credit_applications
    FOR EACH ROW
    EXECUTE FUNCTION notify_credit_application_changes();
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS credit_application_insert_trigger ON credit_applications;"
    execute "DROP TRIGGER IF EXISTS credit_application_update_trigger ON credit_applications;"
    execute "DROP FUNCTION IF EXISTS notify_credit_application_changes();"
  end
end
