defmodule CreditAppWeb.Api.WebhookController do
  use CreditAppWeb, :controller
  require Logger

  alias CreditApp.Applications

  def receive(conn, %{"event" => event, "application_id" => app_id} = params) do
    Logger.info("[WebhookController] Received webhook: #{event} for #{app_id}")

    case event do
      "external_approval" ->
        handle_external_approval(conn, app_id, params)

      "bank_verification_complete" ->
        handle_bank_verification(conn, app_id, params)

      _ ->
        Logger.warning("[WebhookController] Unknown event: #{event}")
        json(conn, %{status: "received", event: event})
    end
  end

  defp handle_external_approval(conn, app_id, params) do
    status = approval_status(params["approved"])

    case Applications.update_status(app_id, status, notes: "External approval webhook") do
      {:ok, _app} ->
        json(conn, %{status: "processed", new_status: status})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  defp handle_bank_verification(conn, app_id, params) do
    bank_data = params["bank_data"] || %{}

    case Applications.update_bank_info(app_id, bank_data) do
      {:ok, _app} ->
        json(conn, %{status: "processed"})

      {:error, _reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to update bank info"})
    end
  end

  defp approval_status(true), do: "approved"
  defp approval_status(_), do: "rejected"
end
