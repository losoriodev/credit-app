defmodule CreditApp.Countries.MXTest do
  use ExUnit.Case, async: true

  alias CreditApp.Countries.MX

  describe "validate_document/1" do
    test "validates a correct CURP" do
      assert :ok = MX.validate_document("BADD110313HCMLNS09")
    end

    test "rejects CURP with wrong format" do
      assert {:error, _} = MX.validate_document("INVALID")
      assert {:error, _} = MX.validate_document("1234567890")
    end
  end

  describe "validate_business_rules/1" do
    test "passes when amount is within 4x income" do
      attrs = %{"amount" => "10000", "monthly_income" => "5000"}
      assert :ok = MX.validate_business_rules(attrs)
    end

    test "fails when amount exceeds 4x income" do
      attrs = %{"amount" => "50000", "monthly_income" => "5000"}
      assert {:error, _} = MX.validate_business_rules(attrs)
    end
  end
end
