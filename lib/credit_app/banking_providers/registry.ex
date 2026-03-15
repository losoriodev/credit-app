defmodule CreditApp.BankingProviders.Registry do
  @moduledoc "Registry to look up banking provider modules by country code."

  @provider_modules %{
    "ES" => CreditApp.BankingProviders.ESProvider,
    "MX" => CreditApp.BankingProviders.MXProvider,
    "CO" => CreditApp.BankingProviders.COProvider
  }

  def get_provider(country_code) do
    case Map.get(@provider_modules, country_code) do
      nil -> {:error, "No banking provider for country: #{country_code}"}
      module -> {:ok, module}
    end
  end

  def fetch_client_info(country_code, identity_document) do
    with {:ok, provider} <- get_provider(country_code) do
      provider.fetch_client_info(identity_document)
    end
  end
end
