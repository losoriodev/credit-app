defmodule CreditApp.Audit do
  @moduledoc "Audit logging context."
  import Ecto.Query
  alias CreditApp.Repo
  alias CreditApp.Audit.AuditLog

  def log(entity_type, entity_id, action, changes \\ %{}, opts \\ []) do
    %AuditLog{}
    |> AuditLog.changeset(%{
      entity_type: entity_type,
      entity_id: entity_id,
      action: action,
      changes: changes,
      actor_id: Keyword.get(opts, :actor_id),
      metadata: Keyword.get(opts, :metadata, %{})
    })
    |> Repo.insert()
  end

  def list_for_entity(entity_type, entity_id) do
    AuditLog
    |> where([a], a.entity_type == ^entity_type and a.entity_id == ^entity_id)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end
end
