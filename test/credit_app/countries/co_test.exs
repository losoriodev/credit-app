defmodule CreditApp.Countries.COTest do
  use ExUnit.Case, async: true

  alias CreditApp.Countries.CO

  describe "validate_document/1" do
    test "validates a correct CC" do
      assert :ok = CO.validate_document("1234567890")
    end

    test "validates CC with 6 digits" do
      assert :ok = CO.validate_document("123456")
    end

    test "rejects CC with wrong format" do
      assert {:error, _} = CO.validate_document("12345")
      assert {:error, _} = CO.validate_document("ABCDEFGHIJ")
    end
  end

  describe "validate_business_rules/1" do
    test "passes when total debt plus amount is within 5x income" do
      attrs = %{
        "amount" => "1000000",
        "monthly_income" => "3000000",
        "bank_info" => %{"total_debt" => "5000000"}
      }
      assert :ok = CO.validate_business_rules(attrs)
    end

    test "fails when total debt exceeds 5x income" do
      attrs = %{
        "amount" => "10000000",
        "monthly_income" => "3000000",
        "bank_info" => %{"total_debt" => "10000000"}
      }
      assert {:error, _} = CO.validate_business_rules(attrs)
    end
  end
end
