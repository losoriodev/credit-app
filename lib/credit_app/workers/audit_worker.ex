defmodule CreditApp.Workers.AuditWorker do
  @moduledoc "Async worker for creating audit log entries."
  use Oban.Worker,
    queue: :audit,
    max_attempts: 5,
    unique: [period: 30, fields: [:args]]

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    base = :math.pow(2, attempt) |> trunc()
    jitter = :rand.uniform(max(base, 1))
    base + jitter
  end

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
