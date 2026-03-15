defmodule CreditApp.Accounts do
  @moduledoc "Accounts context for user management and authentication."
  alias CreditApp.Repo
  alias CreditApp.Accounts.{User, Guardian}

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def authenticate(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user, %{role: user.role, country: user.country})
        {:ok, %{user: user, token: token}}

      user ->
        {:error, :invalid_credentials}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def list_users do
    Repo.all(User)
  end
end
