defmodule CreditApp.BankingProviders.Registry do
  @moduledoc "Registry to look up banking provider modules by country code."
  require Logger

  alias CreditApp.Resilience.CircuitBreaker

  @provider_modules %{
    "ES" => CreditApp.BankingProviders.ESProvider,
    "MX" => CreditApp.BankingProviders.MXProvider,
    "CO" => CreditApp.BankingProviders.COProvider,
    "AR" => CreditApp.BankingProviders.ARProvider
  }

  @call_timeout 10_000

  def get_provider(country_code) do
    case Map.get(@provider_modules, country_code) do
      nil -> {:error, "No banking provider for country: #{country_code}"}
      module -> {:ok, module}
    end
  end

  def fetch_client_info(country_code, identity_document) do
    with {:ok, provider} <- get_provider(country_code) do
      service = "banking_provider:#{country_code}"

      CircuitBreaker.call(service, fn ->
        task = Task.async(fn -> provider.fetch_client_info(identity_document) end)

        case Task.yield(task, @call_timeout) || Task.shutdown(task) do
          {:ok, result} -> result
          nil -> {:error, "Provider call timed out after #{@call_timeout}ms"}
        end
      end)
    end
  end
end
