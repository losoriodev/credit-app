defmodule CreditApp.Countries.ES do
  @moduledoc "Spain country rules. Document: DNI."
  @behaviour CreditApp.Countries.CountryRule

  @high_amount_threshold Decimal.new("50000")
  @control_letters "TRWAGMYFPDXBNJZSQVHLCKE"

  @impl true
  def country_code, do: "ES"

  @impl true
  def document_type, do: "DNI"

  @impl true
  def validate_document(dni) do
    dni = String.trim(dni) |> String.upcase()

    with {:ok, digits, letter} <- parse_dni(dni),
         :ok <- verify_control_letter(digits, letter) do
      :ok
    end
  end

  defp parse_dni(dni) do
    case Regex.run(~r/^(\d{8})([A-Z])$/, dni) do
      [_, digits, letter] -> {:ok, String.to_integer(digits), letter}
      _ -> {:error, "DNI must be 8 digits followed by a letter (e.g., 12345678Z)"}
    end
  end

  defp verify_control_letter(digits, letter) do
    expected = String.at(@control_letters, rem(digits, 23))

    case letter do
      ^expected -> :ok
      _ -> {:error, "DNI control letter is invalid"}
    end
  end

  @impl true
  def validate_business_rules(attrs) do
    amount = to_decimal(attrs["amount"] || attrs[:amount])
    income = to_decimal(attrs["monthly_income"] || attrs[:monthly_income])

    cond do
      Decimal.compare(amount, Decimal.new("0")) != :gt ->
        {:error, "Amount must be greater than zero"}

      Decimal.compare(income, Decimal.new("0")) != :gt ->
        {:error, "Monthly income must be greater than zero"}

      Decimal.compare(Decimal.div(amount, income), Decimal.new("6")) == :gt ->
        {:error, "Requested amount cannot exceed 6x monthly income"}

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
