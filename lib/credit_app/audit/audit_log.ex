defmodule CreditApp.Audit.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_logs" do
    field :entity_type, :string
    field :entity_id, :binary_id
    field :action, :string
    field :changes, :map, default: %{}
    field :actor_id, :binary_id
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:entity_type, :entity_id, :action, :changes, :actor_id, :metadata])
    |> validate_required([:entity_type, :entity_id, :action])
  end
end
