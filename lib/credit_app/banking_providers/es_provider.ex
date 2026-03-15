defmodule CreditApp.BankingProviders.ESProvider do
  @moduledoc "Simulated banking provider for Spain (Banco de España integration)."
  @behaviour CreditApp.BankingProviders.Provider
  require Logger

  @impl true
  def country_code, do: "ES"

  @impl true
  def provider_name, do: "BancoEspañaConnect"

  @impl true
  def fetch_client_info(identity_document) do
    Logger.info("[ESProvider] Fetching bank info for DNI: #{mask_document(identity_document)}")

    # Simulated response from Spanish banking provider
    Process.sleep(Enum.random(100..500))

    {:ok, %{
      "provider" => provider_name(),
      "credit_score" => Enum.random(300..850),
      "existing_loans" => Enum.random(0..3),
      "total_debt" => Enum.random(0..50_000) |> to_string(),
      "account_age_months" => Enum.random(6..240),
      "risk_category" => Enum.random(["low", "medium", "high"]),
      "iban" => "ES#{:rand.uniform(99) |> Integer.to_string() |> String.pad_leading(2, "0")}****",
      "fetched_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }}
  end

  defp mask_document(doc) when byte_size(doc) > 4 do
    String.slice(doc, 0, 4) <> "****"
  end

  defp mask_document(_), do: "****"
end
