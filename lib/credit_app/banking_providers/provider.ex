defmodule CreditApp.BankingProviders.Provider do
  @moduledoc "Behaviour for banking provider integrations."

  @callback country_code() :: String.t()
  @callback provider_name() :: String.t()
  @callback fetch_client_info(String.t()) :: {:ok, map()} | {:error, String.t()}
end
