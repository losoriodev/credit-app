defmodule CreditApp.Countries.Registry do
  @moduledoc "Registry to look up country rule modules by country code."

  @country_modules %{
    "ES" => CreditApp.Countries.ES,
    "MX" => CreditApp.Countries.MX,
    "CO" => CreditApp.Countries.CO,
    "AR" => CreditApp.Countries.AR
  }

  def get_module(country_code) do
    case Map.get(@country_modules, country_code) do
      nil -> {:error, "Unsupported country: #{country_code}"}
      module -> {:ok, module}
    end
  end

  def supported_countries, do: Map.keys(@country_modules)

  def validate(country_code, attrs) do
    with {:ok, module} <- get_module(country_code),
         document <- attrs["identity_document"] || attrs[:identity_document] || "",
         :ok <- module.validate_document(document),
         :ok <- module.validate_business_rules(attrs) do
      :ok
    end
  end
end
