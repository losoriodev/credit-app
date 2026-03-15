defmodule CreditApp.Applications.StateMachineTest do
  use ExUnit.Case, async: true

  alias CreditApp.Applications.StateMachine

  describe "can_transition?/2" do
    test "allows pending -> validating" do
      assert StateMachine.can_transition?("pending", "validating")
    end

    test "allows pending -> cancelled" do
      assert StateMachine.can_transition?("pending", "cancelled")
    end

    test "allows validating -> approved" do
      assert StateMachine.can_transition?("validating", "approved")
    end

    test "allows validating -> rejected" do
      assert StateMachine.can_transition?("validating", "rejected")
    end

    test "denies pending -> approved (must go through validating)" do
      refute StateMachine.can_transition?("pending", "approved")
    end

    test "denies disbursed -> anything (terminal state)" do
      refute StateMachine.can_transition?("disbursed", "pending")
      refute StateMachine.can_transition?("disbursed", "cancelled")
    end
  end

  describe "allowed_transitions/1" do
    test "returns allowed transitions for pending" do
      assert StateMachine.allowed_transitions("pending") == ~w(validating cancelled)
    end

    test "returns empty for terminal states" do
      assert StateMachine.allowed_transitions("disbursed") == []
      assert StateMachine.allowed_transitions("cancelled") == []
    end
  end
end
