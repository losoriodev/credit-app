defmodule CreditApp.BankingProviders.MXProvider do
  @moduledoc "Simulated banking provider for Mexico (Buró de Crédito integration)."
  @behaviour CreditApp.BankingProviders.Provider
  require Logger

  @impl true
  def country_code, do: "MX"

  @impl true
  def provider_name, do: "BuroCreditoMX"

  @impl true
  def fetch_client_info(identity_document) do
    Logger.info("[MXProvider] Fetching bank info for CURP: #{mask_document(identity_document)}")

    Process.sleep(Enum.random(200..800))

    {:ok, %{
      "provider" => provider_name(),
      "score_bc" => Enum.random(400..850),
      "active_credits" => Enum.random(0..5),
      "total_debt" => Enum.random(0..200_000) |> to_string(),
      "payment_history" => Enum.random(["excellent", "good", "regular", "bad"]),
      "months_since_last_default" => Enum.random(0..60),
      "clabe" => "****#{:rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")}",
      "fetched_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }}
  end

  defp mask_document(doc) when byte_size(doc) > 4 do
    String.slice(doc, 0, 4) <> "****"
  end

  defp mask_document(_), do: "****"
end
