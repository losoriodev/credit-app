defmodule CreditAppWeb.Api.AuthController do
  use CreditAppWeb, :controller

  alias CreditApp.Accounts

  action_fallback CreditAppWeb.FallbackController

  def register(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        with {:ok, token, _claims} <- CreditApp.Accounts.Guardian.encode_and_sign(user) do
          conn
          |> put_status(:created)
          |> json(%{
            data: %{
              id: user.id,
              email: user.email,
              role: user.role,
              token: token
            }
          })
        end

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, %{user: user, token: token}} ->
        CreditApp.Audit.log("api_session", nil, "login_success", %{email: email}, actor_id: user.id,
          metadata: %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})

        json(conn, %{
          data: %{
            id: user.id,
            email: user.email,
            role: user.role,
            token: token
          }
        })

      {:error, :invalid_credentials} ->
        CreditApp.Audit.log("api_session", nil, "login_failure", %{email: email},
          metadata: %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})

        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    json(conn, %{
      data: %{
        id: user.id,
        email: user.email,
        role: user.role,
        country: user.country
      }
    })
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
