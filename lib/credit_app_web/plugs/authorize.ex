defmodule CreditAppWeb.Plugs.Authorize do
  @moduledoc """
  Plug for role-based authorization.

  Roles hierarchy:
    - admin: full access to all countries and actions
    - analyst: can create and view applications for their assigned country
    - viewer: read-only access (list and show)
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @role_permissions %{
    "admin" => [:index, :show, :create, :update_status],
    "analyst" => [:index, :show, :create],
    "viewer" => [:index, :show]
  }

  def init(opts), do: opts

  def call(conn, opts) do
    action = Phoenix.Controller.action_name(conn)
    user = Guardian.Plug.current_resource(conn)

    case authorize(user, action, conn.params, opts) do
      :ok ->
        conn

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
        |> halt()
    end
  end

  defp authorize(nil, _action, _params, _opts), do: {:error, "Authentication required"}

  defp authorize(user, action, params, _opts) do
    with :ok <- check_role_permission(user.role, action),
         :ok <- check_country_scope(user, action, params) do
      :ok
    end
  end

  # Check if the user's role allows this action
  defp check_role_permission(role, action) do
    allowed_actions = Map.get(@role_permissions, role, [])

    case action in allowed_actions do
      true -> :ok
      false -> {:error, "Role '#{role}' is not authorized for this action"}
    end
  end

  # Analysts can only create applications for their assigned country
  defp check_country_scope(%{role: "analyst", country: user_country}, :create, params) do
    app_country = get_in(params, ["application", "country"])

    case app_country do
      nil -> :ok
      ^user_country -> :ok
      _ -> {:error, "Analyst can only create applications for #{user_country}"}
    end
  end

  # Analysts can only update status for their country's applications
  defp check_country_scope(%{role: "analyst"}, :update_status, _params) do
    {:error, "Analysts cannot change application status"}
  end

  # Admin and viewer have no country restrictions
  defp check_country_scope(_user, _action, _params), do: :ok
end
