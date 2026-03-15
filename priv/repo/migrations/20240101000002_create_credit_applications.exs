defmodule CreditApp.Repo.Migrations.CreateCreditApplications do
  use Ecto.Migration

  def change do
    create table(:credit_applications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :country, :string, null: false
      add :full_name, :string, null: false
      add :identity_document, :string, null: false
      add :amount, :decimal, null: false
      add :monthly_income, :decimal, null: false
      add :application_date, :date, null: false
      add :status, :string, null: false, default: "pending"
      add :bank_info, :map, default: %{}
      add :risk_score, :decimal
      add :notes, :text
      add :metadata, :map, default: %{}
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    # Performance indexes for high-volume queries
    create index(:credit_applications, [:country])
    create index(:credit_applications, [:status])
    create index(:credit_applications, [:country, :status])
    create index(:credit_applications, [:application_date])
    create index(:credit_applications, [:country, :application_date])
    create index(:credit_applications, [:inserted_at])
    create index(:credit_applications, [:identity_document, :country])
  end
end
