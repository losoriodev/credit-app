defmodule CreditApp.Applications.StateMachine do
  @moduledoc """
  State machine for credit application status transitions.
  Each country can define its own allowed transitions, but there are common defaults.
  """
  require Logger

  @default_transitions %{
    "pending" => ~w(validating cancelled),
    "validating" => ~w(approved rejected review_required),
    "review_required" => ~w(validating approved rejected cancelled),
    "approved" => ~w(disbursed cancelled),
    "rejected" => ~w(pending),
    "disbursed" => [],
    "cancelled" => []
  }

  def can_transition?(from, to, _country \\ nil) do
    allowed = Map.get(transitions(), from, [])
    to in allowed
  end

  def transition(application, new_status) do
    case can_transition?(application.status, new_status) do
      true -> {:ok, new_status}
      false -> {:error, "Cannot transition from '#{application.status}' to '#{new_status}'"}
    end
  end

  def allowed_transitions(status) do
    Map.get(transitions(), status, [])
  end

  defp transitions, do: @default_transitions
end
