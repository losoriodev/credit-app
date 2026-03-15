defmodule CreditAppWeb.Api.CreditApplicationController do
  use CreditAppWeb, :controller

  alias CreditApp.Applications
  alias CreditApp.Applications.CreditApplication

  plug CreditAppWeb.Plugs.Authorize

  action_fallback CreditAppWeb.FallbackController

  def index(conn, params) do
    applications = Applications.list_applications(params)
    json(conn, %{data: Enum.map(applications, &serialize/1)})
  end

  def create(conn, %{"application" => app_params}) do
    user = Guardian.Plug.current_resource(conn)
    app_params = Map.put(app_params, "user_id", user.id)

    case Applications.create_application(app_params) do
      {:ok, application} ->
        conn
        |> put_status(:created)
        |> json(%{data: serialize(application)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})

      {:error, message} when is_binary(message) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{validation: message}})
    end
  end

  def show(conn, %{"id" => id}) do
    case Applications.get_application(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Application not found"})

      application ->
        json(conn, %{data: serialize(application)})
    end
  end

  def update_status(conn, %{"id" => id, "status" => new_status} = params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [notes: params["notes"], actor_id: user.id]

    case Applications.update_status(id, new_status, opts) do
      {:ok, application} ->
        json(conn, %{data: serialize(application)})

      {:error, message} when is_binary(message) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{status: message}})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  defp serialize(%CreditApplication{} = app) do
    %{
      id: app.id,
      country: app.country,
      full_name: app.full_name,
      identity_document: mask_document(app.identity_document),
      amount: app.amount,
      monthly_income: app.monthly_income,
      application_date: app.application_date,
      status: app.status,
      risk_score: app.risk_score,
      notes: app.notes,
      bank_info: sanitize_bank_info(app.bank_info),
      inserted_at: app.inserted_at,
      updated_at: app.updated_at
    }
  end

  # PII protection: mask identity documents in API responses
  defp mask_document(doc) when is_binary(doc) and byte_size(doc) > 4 do
    visible = String.slice(doc, 0, 4)
    masked = String.duplicate("*", max(byte_size(doc) - 4, 0))
    visible <> masked
  end

  defp mask_document(doc), do: doc

  # Remove sensitive banking details from API responses
  defp sanitize_bank_info(nil), do: nil
  defp sanitize_bank_info(info) when is_map(info) do
    Map.drop(info, ["iban", "clabe", "bank_account"])
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
