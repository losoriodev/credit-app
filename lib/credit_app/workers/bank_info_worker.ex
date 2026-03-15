defmodule CreditApp.Workers.BankInfoWorker do
  @moduledoc """
  Async worker that fetches banking information from the country's provider.
  Runs after a credit application is created.
  """
  use Oban.Worker,
    queue: :banking,
    max_attempts: 3,
    unique: [period: 120, fields: [:args], keys: [:id]]

  require Logger
  alias CreditApp.Applications
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
    with {:ok, bank_info} <- Registry.fetch_client_info(country, document),
         {:ok, _updated} <- Applications.update_bank_info(id, bank_info) do
      case application.status do
        "pending" ->
          Applications.update_status(id, "validating", notes: "Bank info received, starting validation")

        _ ->
          :ok
      end

      Logger.info("[BankInfoWorker] Bank info fetched successfully for #{id}")
      :ok
    end
  end
end
