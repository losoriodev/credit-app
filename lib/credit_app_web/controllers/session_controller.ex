defmodule CreditAppWeb.SessionController do
  use CreditAppWeb, :controller

  alias CreditApp.Accounts
  alias CreditApp.Audit

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, %{user: user}} ->
        Audit.log("session", nil, "login_success", %{email: email}, actor_id: user.id,
          metadata: %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})

        conn
        |> put_session(:current_user_id, user.id)
        |> put_session(:current_user_role, user.role)
        |> put_session(:current_user_country, user.country)
        |> put_session(:current_user_email, user.email)
        |> redirect(to: ~p"/")

      {:error, _} ->
        Audit.log("session", nil, "login_failure", %{email: email},
          metadata: %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})

        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/login")
  end
end
