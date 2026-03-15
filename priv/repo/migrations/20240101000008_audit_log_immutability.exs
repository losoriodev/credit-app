defmodule CreditApp.Repo.Migrations.AuditLogImmutability do
  use Ecto.Migration

  def up do
    # Make entity_id nullable for non-entity audit events (e.g., login attempts)
    alter table(:audit_logs) do
      modify :entity_id, :binary_id, null: true
    end

    # Composite index for efficient filtering
    create index(:audit_logs, [:entity_type, :action])

    # PostgreSQL RULEs to prevent UPDATE and DELETE on audit_logs
    execute """
    CREATE RULE audit_logs_no_update AS ON UPDATE TO audit_logs DO INSTEAD NOTHING;
    """

    execute """
    CREATE RULE audit_logs_no_delete AS ON DELETE TO audit_logs DO INSTEAD NOTHING;
    """
  end

  def down do
    execute "DROP RULE IF EXISTS audit_logs_no_delete ON audit_logs;"
    execute "DROP RULE IF EXISTS audit_logs_no_update ON audit_logs;"

    drop_if_exists index(:audit_logs, [:entity_type, :action])

    alter table(:audit_logs) do
      modify :entity_id, :binary_id, null: false
    end
  end
end
