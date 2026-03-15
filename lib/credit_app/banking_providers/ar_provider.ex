defmodule CreditApp.BankingProviders.ARProvider do
  @moduledoc "Simulated banking provider for Argentina (BancoNacionAR integration)."
  @behaviour CreditApp.BankingProviders.Provider
  require Logger

  @impl true
  def country_code, do: "AR"

  @impl true
  def provider_name, do: "BancoNacionAR"

  @impl true
  def fetch_client_info(identity_document) do
    Logger.info("[ARProvider] Fetching bank info for CUIT: #{mask_document(identity_document)}")

    Process.sleep(Enum.random(150..600))

    {:ok, %{
      "provider" => provider_name(),
      "score" => Enum.random(150..950),
      "total_debt" => Enum.random(0..2_000_000) |> to_string(),
      "active_obligations" => Enum.random(0..5),
      "max_days_overdue" => Enum.random(0..120),
      "reported_income" => Enum.random(100_000..3_000_000) |> to_string(),
      "bank_account" => "****#{:rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")}",
      "fetched_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }}
  end

  defp mask_document(doc) when byte_size(doc) > 4 do
    String.slice(doc, 0, 4) <> "****"
  end

  defp mask_document(_), do: "****"
end
