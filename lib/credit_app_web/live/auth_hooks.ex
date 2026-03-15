defmodule CreditAppWeb.AuthHooks do
  @moduledoc "LiveView on_mount hooks for session-based authentication."
  import Phoenix.LiveView
  import Phoenix.Component

  alias CreditApp.Accounts

  def on_mount(:require_auth, _params, session, socket) do
    case session["current_user_id"] do
      nil ->
        {:halt, redirect(socket, to: "/login")}

      user_id ->
        user = Accounts.get_user(user_id)

        case user do
          nil ->
            {:halt, redirect(socket, to: "/login")}

          user ->
            {:cont,
             socket
             |> assign(:current_user, user)
             |> assign(:current_role, user.role)
             |> assign(:current_country, user.country)}
        end
    end
  end

  def on_mount(:guest_only, _params, session, socket) do
    case session["current_user_id"] do
      nil -> {:cont, socket}
      _ -> {:halt, redirect(socket, to: "/")}
    end
  end
end
