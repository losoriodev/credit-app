defmodule CreditApp.Workers.DeadLetterHandler do
  @moduledoc """
  Telemetry handler for Oban jobs that have exhausted all retries.
  Logs the failure and creates an audit entry for investigation.
  """
  require Logger

  def attach do
    :telemetry.attach(
      "oban-dead-letter-handler",
      [:oban, :job, :exception],
      &__MODULE__.handle_event/4,
      %{}
    )
  end

  def handle_event([:oban, :job, :exception], _measurements, metadata, _config) do
    job = metadata[:job] || metadata

    # Only handle jobs that have exhausted all attempts
    attempt = get_in_job(job, :attempt)
    max_attempts = get_in_job(job, :max_attempts)

    if attempt >= max_attempts do
      worker = get_in_job(job, :worker) || "unknown"
      queue = get_in_job(job, :queue) || "unknown"
      args = get_in_job(job, :args) || %{}
      error = format_error(metadata)

      Logger.error(
        "[DeadLetterHandler] Job exhausted: worker=#{worker} queue=#{queue} args=#{inspect(args)} error=#{error}"
      )

      # Create audit entry asynchronously to avoid blocking
      Task.start(fn ->
        CreditApp.Audit.log(
          "oban_job",
          args["id"],
          "job_exhausted",
          %{
            worker: worker,
            queue: queue,
            args: args,
            error: error,
            attempt: attempt,
            max_attempts: max_attempts
          }
        )
      end)
    end
  end

  defp get_in_job(%{} = job, key) when is_atom(key) do
    Map.get(job, key) || Map.get(job, to_string(key))
  end

  defp get_in_job(_, _), do: nil

  defp format_error(%{reason: reason}), do: inspect(reason)
  defp format_error(%{error: error}), do: inspect(error)
  defp format_error(_), do: "unknown"
end
