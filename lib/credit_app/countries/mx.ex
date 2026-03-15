defmodule CreditApp.Countries.MX do
  @moduledoc "Mexico country rules. Document: CURP."
  @behaviour CreditApp.Countries.CountryRule

  @high_amount_threshold Decimal.new("500000")
  @curp_regex ~r/^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z\d]\d$/

  @impl true
  def country_code, do: "MX"

  @impl true
  def document_type, do: "CURP"

  @impl true
  def validate_document(curp) do
    curp = String.trim(curp) |> String.upcase()

    case Regex.match?(@curp_regex, curp) do
      true -> :ok
      false -> {:error, "CURP must be 18 characters with format: 4 letters + 6 digits + H/M + 5 letters + alphanumeric + digit"}
    end
  end

  @impl true
  def validate_business_rules(attrs) do
    amount = to_decimal(attrs["amount"] || attrs[:amount])
    income = to_decimal(attrs["monthly_income"] || attrs[:monthly_income])

    cond do
      Decimal.compare(income, Decimal.new("0")) != :gt ->
        {:error, "Monthly income must be greater than zero"}

      Decimal.compare(Decimal.div(amount, income), Decimal.new("4")) == :gt ->
        {:error, "Requested amount cannot exceed 4x monthly income in Mexico"}

      true ->
        :ok
    end
  end

  @impl true
  def high_amount_threshold, do: @high_amount_threshold

  @impl true
  def requires_additional_review?(attrs) do
    amount = to_decimal(attrs["amount"] || attrs[:amount])
    income = to_decimal(attrs["monthly_income"] || attrs[:monthly_income])

    Decimal.compare(amount, @high_amount_threshold) in [:gt, :eq] or
      Decimal.compare(Decimal.div(amount, income), Decimal.new("3")) == :gt
  end

  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(v) when is_binary(v), do: Decimal.new(v)
  defp to_decimal(v) when is_integer(v), do: Decimal.new(v)
  defp to_decimal(_), do: Decimal.new("0")
end
