defmodule CreditApp.Repo.Listener do
  @moduledoc """
  Listens to PostgreSQL NOTIFY events on the 'credit_application_changes' channel.
  When a credit application is inserted or updated, PostgreSQL triggers send a notification
  which this process picks up and broadcasts via PubSub + enqueues Oban jobs.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(_state) do
    {:ok, %{}, {:continue, :listen}}
  end

  @impl GenServer
  def handle_continue(:listen, state) do
    case Postgrex.Notifications.start_link(CreditApp.Repo.config()) do
      {:ok, pid} ->
        Postgrex.Notifications.listen!(pid, "credit_application_changes")
        Logger.info("[Repo.Listener] Listening on credit_application_changes channel")
        {:noreply, Map.put(state, :pid, pid)}

      {:error, reason} ->
        Logger.warning("[Repo.Listener] Failed to connect for LISTEN: #{inspect(reason)}, retrying in 5s")
        Process.send_after(self(), :retry_listen, 5_000)
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:notification, _pid, _ref, "credit_application_changes", payload}, state) do
    case Jason.decode(payload) do
      {:ok, %{"operation" => operation, "id" => id, "country" => country, "status" => status}} ->
        handle_db_event(operation, id, country, status)

      {:error, _} ->
        Logger.error("[Repo.Listener] Failed to decode notification: #{payload}")
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:retry_listen, state) do
    {:noreply, state, {:continue, :listen}}
  end

  @impl GenServer
  def handle_info(_msg, state), do: {:noreply, state}

  defp handle_db_event(operation, id, country, status) do
    Logger.info("[Repo.Listener] DB event: #{operation} on application #{id} (#{country}/#{status})")

    change_payload = {:application_changed, %{id: id, operation: operation, country: country, status: status}}
    Phoenix.PubSub.broadcast(CreditApp.PubSub, "applications:#{country}", change_payload)
    Phoenix.PubSub.broadcast(CreditApp.PubSub, "application:#{id}", change_payload)

    maybe_enqueue_risk_assessment(operation, id)
  end

  defp maybe_enqueue_risk_assessment("INSERT", id) do
    %{id: id}
    |> CreditApp.Workers.RiskAssessmentWorker.new()
    |> Oban.insert()
  end

  defp maybe_enqueue_risk_assessment(_operation, _id), do: :ok
end
