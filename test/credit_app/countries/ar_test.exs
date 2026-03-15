defmodule CreditApp.Countries.ARTest do
  use ExUnit.Case, async: true

  alias CreditApp.Countries.AR

  describe "validate_document/1" do
    test "validates a correct CUIT with valid check digit" do
      # 20-27395162-9 is a valid CUIT (type 20, DNI 27395162, check digit 9)
      assert :ok = AR.validate_document("20273951629")
    end

    test "validates CUIT with dashes" do
      assert :ok = AR.validate_document("20-27395162-9")
    end

    test "rejects CUIT with wrong length" do
      assert {:error, "CUIT/CUIL must be 11 digits"} = AR.validate_document("1234567890")
      assert {:error, "CUIT/CUIL must be 11 digits"} = AR.validate_document("123456789012")
    end

    test "rejects CUIT with non-digit characters" do
      assert {:error, "CUIT/CUIL must contain only digits"} = AR.validate_document("2027395162A")
    end

    test "rejects CUIT with invalid check digit" do
      assert {:error, "CUIT/CUIL has invalid check digit"} = AR.validate_document("20273951620")
    end
  end

  describe "validate_business_rules/1" do
    test "passes when total debt plus amount is within 5x income" do
      attrs = %{
        "amount" => "100000",
        "monthly_income" => "300000",
        "bank_info" => %{"total_debt" => "500000"}
      }
      assert :ok = AR.validate_business_rules(attrs)
    end

    test "fails when total debt exceeds 5x income" do
      attrs = %{
        "amount" => "1000000",
        "monthly_income" => "300000",
        "bank_info" => %{"total_debt" => "1000000"}
      }
      assert {:error, _} = AR.validate_business_rules(attrs)
    end

    test "fails when monthly income is zero" do
      attrs = %{
        "amount" => "100000",
        "monthly_income" => "0"
      }
      assert {:error, "Monthly income must be greater than zero"} = AR.validate_business_rules(attrs)
    end
  end

  describe "high_amount_threshold/0" do
    test "returns 500,000 ARS" do
      assert Decimal.equal?(AR.high_amount_threshold(), Decimal.new("500000"))
    end
  end

  describe "requires_additional_review?/1" do
    test "requires review for amounts >= threshold" do
      assert AR.requires_additional_review?(%{"amount" => "500000"})
      assert AR.requires_additional_review?(%{"amount" => "600000"})
    end

    test "does not require review for amounts below threshold" do
      refute AR.requires_additional_review?(%{"amount" => "499999"})
    end
  end
end
