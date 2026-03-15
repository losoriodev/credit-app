defmodule CreditApp.Workers.BankInfoWorker do
  @moduledoc """
  Async worker that fetches banking information from the country's provider.
  Runs after a credit application is created.
  """
  use Oban.Worker,
    queue: :banking,
    max_attempts: 5,
    unique: [period: 120, fields: [:args], keys: [:id]]

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    base = :math.pow(2, attempt) |> trunc()
    jitter = :rand.uniform(max(base, 1))
    base + jitter
  end

  require Logger
  alias CreditApp.Applications
  alias CreditApp.Audit
  alias CreditApp.BankingProviders.Registry

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "country" => country, "document" => document}}) do
    Logger.info("[BankInfoWorker] Fetching bank info for application #{id} (#{country})")

    application = Applications.get_application!(id)

    # Idempotency: skip if bank info already populated
    case application.bank_info do
      info when info != %{} and not is_nil(info) ->
        Logger.info("[BankInfoWorker] Bank info already exists for #{id}, skipping")
        :ok

      _ ->
        fetch_and_update(id, country, document, application)
    end
  end

  defp fetch_and_update(id, country, document, application) do
    start_time = System.monotonic_time()

    with {:ok, bank_info} <- Registry.fetch_client_info(country, document),
         {:ok, _updated} <- Applications.update_bank_info(id, bank_info) do
      :telemetry.execute(
        [:credit_app, :provider, :call],
        %{duration: System.monotonic_time() - start_time},
        %{provider: country}
      )
      case application.status do
        "pending" ->
          Applications.update_status(id, "validating", notes: "Bank info received, starting validation")

        _ ->
          :ok
      end

      Logger.info("[BankInfoWorker] Bank info fetched successfully for #{id}")
      Audit.log("credit_application", id, "bank_info_fetched",
        %{provider: country}, metadata: %{duration_ms: System.convert_time_unit(System.monotonic_time() - start_time, :native, :millisecond)})
      :ok
    else
      {:error, reason} = error ->
        :telemetry.execute(
          [:credit_app, :provider, :call, :error],
          %{count: 1},
          %{provider: country}
        )

        Audit.log("credit_application", id, "bank_info_failed",
          %{provider: country, error: inspect(reason)})
        Logger.error("[BankInfoWorker] Provider call failed for #{id}: #{inspect(reason)}")
        error
    end
  end
end
