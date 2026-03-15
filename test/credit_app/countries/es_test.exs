defmodule CreditApp.Countries.ESTest do
  use ExUnit.Case, async: true

  alias CreditApp.Countries.ES

  describe "validate_document/1" do
    test "validates a correct DNI" do
      assert :ok = ES.validate_document("12345678Z")
    end

    test "rejects DNI with wrong control letter" do
      assert {:error, _} = ES.validate_document("12345678A")
    end

    test "rejects DNI with wrong format" do
      assert {:error, _} = ES.validate_document("1234567")
      assert {:error, _} = ES.validate_document("ABCDEFGHZ")
    end
  end

  describe "validate_business_rules/1" do
    test "passes when amount is within income ratio" do
      attrs = %{"amount" => "10000", "monthly_income" => "3000"}
      assert :ok = ES.validate_business_rules(attrs)
    end

    test "fails when amount exceeds 6x income" do
      attrs = %{"amount" => "100000", "monthly_income" => "3000"}
      assert {:error, _} = ES.validate_business_rules(attrs)
    end
  end

  describe "requires_additional_review?/1" do
    test "returns true for high amounts" do
      assert ES.requires_additional_review?(%{amount: Decimal.new("60000")})
    end

    test "returns false for normal amounts" do
      refute ES.requires_additional_review?(%{amount: Decimal.new("10000")})
    end
  end
end
