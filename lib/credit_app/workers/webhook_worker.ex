defmodule CreditApp.Workers.WebhookWorker do
  @moduledoc """
  Async worker that sends webhook notifications to external systems.
  Simulates sending a POST to an external webhook endpoint.
  """
  use Oban.Worker,
    queue: :webhooks,
    max_attempts: 5,
    unique: [period: 60, fields: [:args]]

  require Logger

  @default_webhook_url "https://httpbin.org/post"

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"application_id" => app_id, "event" => event, "data" => data}}) do
    Logger.info("[WebhookWorker] Sending webhook for #{event} on application #{app_id}")

    payload = %{
      event: event,
      application_id: app_id,
      data: data,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    webhook_url = Application.get_env(:credit_app, :webhook_url, @default_webhook_url)

    case Req.post(webhook_url, json: payload, receive_timeout: 10_000) do
      {:ok, %{status: status}} when status in 200..299 ->
        Logger.info("[WebhookWorker] Webhook sent successfully for #{app_id}")
        :ok

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
