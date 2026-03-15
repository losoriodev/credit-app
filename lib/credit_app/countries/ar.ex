defmodule CreditApp.Countries.AR do
  @moduledoc "Argentina country rules. Document: CUIT/CUIL (11 digits with check digit)."
  @behaviour CreditApp.Countries.CountryRule

  @high_amount_threshold Decimal.new("500000")
  @cuit_weights [5, 4, 3, 2, 7, 6, 5, 4, 3, 2]

  @impl true
  def country_code, do: "AR"

  @impl true
  def document_type, do: "CUIT"

  @impl true
  def validate_document(cuit) do
    cuit = cuit |> String.trim() |> String.replace("-", "")

    with {:length, true} <- {:length, String.length(cuit) == 11},
         {:digits, true} <- {:digits, Regex.match?(~r/^\d{11}$/, cuit)},
         {:check, true} <- {:check, valid_check_digit?(cuit)} do
      :ok
    else
      {:length, false} -> {:error, "CUIT/CUIL must be 11 digits"}
      {:digits, false} -> {:error, "CUIT/CUIL must contain only digits"}
      {:check, false} -> {:error, "CUIT/CUIL has invalid check digit"}
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

  defp valid_check_digit?(cuit) do
    digits = cuit |> String.graphemes() |> Enum.map(&String.to_integer/1)
    check = List.last(digits)
    body = Enum.take(digits, 10)

    sum =
      Enum.zip(body, @cuit_weights)
      |> Enum.map(fn {d, w} -> d * w end)
      |> Enum.sum()

    remainder = rem(sum, 11)

    expected =
      case 11 - remainder do
        11 -> 0
        10 -> 9
        n -> n
      end

    check == expected
  end

  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(v) when is_binary(v), do: Decimal.new(v)
  defp to_decimal(v) when is_integer(v), do: Decimal.new(v)
  defp to_decimal(_), do: Decimal.new("0")
end
