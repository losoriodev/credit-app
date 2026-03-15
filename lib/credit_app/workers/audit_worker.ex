defmodule CreditApp.Workers.AuditWorker do
  @moduledoc "Async worker for creating audit log entries."
  use Oban.Worker,
    queue: :audit,
    max_attempts: 3,
    unique: [period: 30, fields: [:args]]

  require Logger
  alias CreditApp.Audit

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.info("[AuditWorker] Logging audit: #{args["action"]} on #{args["entity_type"]} #{args["entity_id"]}")

    case Audit.log(
           args["entity_type"],
           args["entity_id"],
           args["action"],
           args["changes"] || %{},
           actor_id: args["actor_id"],
           metadata: args["metadata"] || %{}
         ) do
      {:ok, _log} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
