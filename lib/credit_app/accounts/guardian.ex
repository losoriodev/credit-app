defmodule CreditApp.Accounts.Guardian do
  use Guardian, otp_app: :credit_app

  alias CreditApp.Accounts

  @impl Guardian
  def subject_for_token(%{id: id}, _claims), do: {:ok, id}

  @impl Guardian
  def subject_for_token(_, _), do: {:error, :invalid_resource}

  @impl Guardian
  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  @impl Guardian
  def resource_from_claims(_), do: {:error, :invalid_claims}
end
