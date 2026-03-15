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

  def list_audit_logs(filters \\ %{}) do
    page = Map.get(filters, "page", 1)
    per_page = Map.get(filters, "per_page", 50)
    offset = (page - 1) * per_page

    query =
      AuditLog
      |> apply_audit_filters(filters)
      |> order_by([a], desc: a.inserted_at)

    total = Repo.aggregate(query, :count, :id)

    entries =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{entries: entries, total: total, page: page, per_page: per_page}
  end

  defp apply_audit_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"entity_type", type}, q when is_binary(type) and type != "" ->
        where(q, [a], a.entity_type == ^type)

      {"action", action}, q when is_binary(action) and action != "" ->
        where(q, [a], a.action == ^action)

      {"from_date", date}, q when is_binary(date) and date != "" ->
        where(q, [a], a.inserted_at >= ^parse_datetime(date))

      {"to_date", date}, q when is_binary(date) and date != "" ->
        where(q, [a], a.inserted_at <= ^parse_datetime(date))

      {"entity_id", id}, q when is_binary(id) and id != "" ->
        where(q, [a], a.entity_id == ^id)

      _, q ->
        q
    end)
  end

  defp parse_datetime(date_string) do
    case DateTime.from_iso8601(date_string <> "T00:00:00Z") do
      {:ok, dt, _} -> dt
      _ -> ~U[1970-01-01 00:00:00Z]
    end
  end
end
