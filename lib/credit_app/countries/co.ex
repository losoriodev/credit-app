defmodule CreditApp.Countries.CO do
  @moduledoc "Colombia country rules. Document: Cédula de Ciudadanía (CC)."
  @behaviour CreditApp.Countries.CountryRule

  @high_amount_threshold Decimal.new("100000000")
  @cc_regex ~r/^\d{6,10}$/

  @impl true
  def country_code, do: "CO"

  @impl true
  def document_type, do: "CC"

  @impl true
  def validate_document(cc) do
    cc = String.trim(cc)

    case Regex.match?(@cc_regex, cc) do
      true -> :ok
      false -> {:error, "Cédula de Ciudadanía must be between 6 and 10 digits"}
    end
  end

  @impl true
  def validate_business_rules(attrs) do
    amount = to_decimal(attrs["amount"] || attrs[:amount])
    income = to_decimal(attrs["monthly_income"] || attrs[:monthly_income])
    bank_info = attrs["bank_info"] || attrs[:bank_info] || %{}
    total_debt = to_decimal(bank_info["total_debt"] || bank_info[:total_debt] || "0")

    debt_plus_amount = Decimal.add(total_debt, amount)

    cond do
      Decimal.compare(income, Decimal.new("0")) != :gt ->
        {:error, "Monthly income must be greater than zero"}

      Decimal.compare(Decimal.div(debt_plus_amount, income), Decimal.new("5")) == :gt ->
        {:error, "Total debt (including requested amount) cannot exceed 5x monthly income"}

      true ->
        :ok
    end
  end

  @impl true
  def high_amount_threshold, do: @high_amount_threshold

  @impl true
  def requires_additional_review?(attrs) do
    amount = to_decimal(attrs["amount"] || attrs[:amount])
    Decimal.compare(amount, @high_amount_threshold) in [:gt, :eq]
  end

  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(v) when is_binary(v), do: Decimal.new(v)
  defp to_decimal(v) when is_integer(v), do: Decimal.new(v)
  defp to_decimal(_), do: Decimal.new("0")
end
