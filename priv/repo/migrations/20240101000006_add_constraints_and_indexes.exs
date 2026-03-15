defmodule CreditApp.Repo.Migrations.AddConstraintsAndIndexes do
  use Ecto.Migration

  def change do
    # Optimistic locking
    alter table(:credit_applications) do
      add :lock_version, :integer, default: 1, null: false
    end

    # Missing FK index
    create index(:credit_applications, [:user_id])

    # Missing audit_logs index
    create index(:audit_logs, [:actor_id])

    # CHECK constraints for credit_applications
    create constraint(:credit_applications, :valid_country,
      check: "country IN ('ES', 'MX', 'CO', 'PT', 'IT', 'BR')"
    )

    create constraint(:credit_applications, :valid_status,
      check: "status IN ('pending', 'validating', 'approved', 'rejected', 'review_required', 'cancelled', 'disbursed')"
    )

    create constraint(:credit_applications, :positive_amount,
      check: "amount > 0"
    )

    create constraint(:credit_applications, :positive_income,
      check: "monthly_income > 0"
    )

    # CHECK constraints for users
    create constraint(:users, :valid_role,
      check: "role IN ('admin', 'analyst', 'viewer')"
    )
  end
end
