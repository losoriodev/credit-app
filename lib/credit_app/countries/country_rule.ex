defmodule CreditApp.Countries.CountryRule do
  @moduledoc """
  Behaviour that each country must implement to provide
  document validation and business rules.
  """

  @callback country_code() :: String.t()
  @callback document_type() :: String.t()
  @callback validate_document(String.t()) :: :ok | {:error, String.t()}
  @callback validate_business_rules(map()) :: :ok | {:error, String.t()}
  @callback high_amount_threshold() :: Decimal.t()
  @callback requires_additional_review?(map()) :: boolean()
end
