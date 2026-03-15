defmodule CreditAppWeb.ApplicationLive.Show do
  use CreditAppWeb, :live_view

  alias CreditApp.Applications
  alias CreditApp.Applications.StateMachine
  alias CreditApp.Audit

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    application = Applications.get_application!(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(CreditApp.PubSub, "application:#{id}")
    end

    audit_logs = Audit.list_for_entity("credit_application", id)

    {:ok,
     socket
     |> assign(:page_title, "Application #{String.slice(id, 0, 8)}...")
     |> assign(:application, application)
     |> assign(:audit_logs, audit_logs)
     |> assign(:allowed_transitions, StateMachine.allowed_transitions(application.status))}
  end

  @impl true
  def handle_event("update_status", %{"status" => new_status}, socket) do
    app = socket.assigns.application

    case Applications.update_status(app.id, new_status) do
      {:ok, updated} ->
        audit_logs = Audit.list_for_entity("credit_application", app.id)

        {:noreply,
         socket
         |> assign(:application, updated)
         |> assign(:audit_logs, audit_logs)
         |> assign(:allowed_transitions, StateMachine.allowed_transitions(updated.status))
         |> put_flash(:info, "Status updated to #{new_status}")}

      {:error, message} when is_binary(message) ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status")}
    end
  end

  @impl true
  def handle_info({:application_changed, _payload}, socket) do
    application = Applications.get_application!(socket.assigns.application.id)
    audit_logs = Audit.list_for_entity("credit_application", application.id)

    {:noreply,
     socket
     |> assign(:application, application)
     |> assign(:audit_logs, audit_logs)
     |> assign(:allowed_transitions, StateMachine.allowed_transitions(application.status))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-8">
      <div class="mb-6">
        <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-800">&larr; Back to list</.link>
      </div>

      <!-- Real-time indicator -->
      <div class="mb-4 text-sm text-green-600 flex items-center gap-2">
        <span class="relative flex h-3 w-3">
          <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
          <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
        </span>
        Live updates enabled
      </div>

      <div class="bg-white shadow-lg rounded-lg overflow-hidden">
        <!-- Header -->
        <div class="px-6 py-4 bg-gray-50 border-b flex justify-between items-center">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">{@application.full_name}</h1>
            <p class="text-sm text-gray-500">ID: {@application.id}</p>
          </div>
          <span class={"inline-flex items-center px-3 py-1 rounded-full text-sm font-medium #{status_color(@application.status)}"}>
            {@application.status}
          </span>
        </div>

        <!-- Details -->
        <div class="px-6 py-6 grid grid-cols-2 gap-6">
          <div>
            <h3 class="text-sm font-medium text-gray-500">Country</h3>
            <p class="mt-1 text-lg">{country_name(@application.country)} ({@application.country})</p>
          </div>
          <div>
            <h3 class="text-sm font-medium text-gray-500">Identity Document</h3>
            <p class="mt-1 text-lg">{mask_document(@application.identity_document)}</p>
          </div>
          <div>
            <h3 class="text-sm font-medium text-gray-500">Requested Amount</h3>
            <p class="mt-1 text-lg font-semibold">{format_amount(@application.amount, @application.country)}</p>
          </div>
          <div>
            <h3 class="text-sm font-medium text-gray-500">Monthly Income</h3>
            <p class="mt-1 text-lg">{format_amount(@application.monthly_income, @application.country)}</p>
          </div>
          <div>
            <h3 class="text-sm font-medium text-gray-500">Application Date</h3>
            <p class="mt-1 text-lg">{@application.application_date}</p>
          </div>
          <div>
            <h3 class="text-sm font-medium text-gray-500">Risk Score</h3>
            <p class={"mt-1 text-lg font-semibold #{risk_color(@application.risk_score)}"}>
              {if @application.risk_score, do: "#{Decimal.round(@application.risk_score, 4)}", else: "Pending..."}
            </p>
          </div>
        </div>

        <!-- Bank Info -->
        <div :if={@application.bank_info && @application.bank_info != %{}} class="px-6 py-4 border-t">
          <h3 class="text-sm font-medium text-gray-500 mb-2">Banking Information</h3>
          <div class="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-lg">
            <div :for={{key, value} <- sanitize_bank_info(@application.bank_info)}>
              <span class="text-xs text-gray-500">{humanize_key(key)}</span>
              <p class="text-sm font-medium">{value}</p>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div :if={@application.notes} class="px-6 py-4 border-t">
          <h3 class="text-sm font-medium text-gray-500 mb-1">Notes</h3>
          <p class="text-sm text-gray-700">{@application.notes}</p>
        </div>

        <!-- Status Transitions (admin only) -->
        <div :if={@allowed_transitions != [] and @current_role == "admin"} class="px-6 py-4 border-t">
          <h3 class="text-sm font-medium text-gray-500 mb-3">Update Status</h3>
          <div class="flex gap-2 flex-wrap">
            <button :for={status <- @allowed_transitions}
              phx-click="update_status"
              phx-value-status={status}
              class={"px-4 py-2 rounded-lg text-sm font-medium shadow-sm #{transition_button_color(status)}"}>
              {String.replace(status, "_", " ") |> String.capitalize()}
            </button>
          </div>
        </div>
      </div>

      <!-- Audit Log -->
      <div class="mt-8">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Audit Trail</h2>
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <div :for={log <- @audit_logs} class="px-6 py-3 border-b last:border-0 flex justify-between items-center">
            <div>
              <span class="font-medium text-sm">{log.action}</span>
              <span :if={log.changes["from"]} class="text-sm text-gray-500 ml-2">
                {log.changes["from"]} &rarr; {log.changes["to"]}
              </span>
            </div>
            <span class="text-xs text-gray-400">{Calendar.strftime(log.inserted_at, "%Y-%m-%d %H:%M:%S UTC")}</span>
          </div>
          <div :if={@audit_logs == []} class="p-6 text-center text-gray-500 text-sm">
            No audit entries yet.
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp mask_document(doc) when is_binary(doc) and byte_size(doc) > 4 do
    String.slice(doc, 0, 4) <> String.duplicate("*", max(byte_size(doc) - 4, 0))
  end

  defp mask_document(doc), do: doc

  defp sanitize_bank_info(info) when is_map(info) do
    Map.drop(info, ["iban", "clabe", "bank_account"])
    |> Enum.sort()
  end

  defp sanitize_bank_info(_), do: []

  defp humanize_key(key) do
    key |> String.replace("_", " ") |> String.capitalize()
  end

  defp format_amount(amount, country) do
    symbol = case country do
      "ES" -> "EUR"
      "MX" -> "MXN"
      "CO" -> "COP"
      _ -> ""
    end
    "#{Decimal.round(amount, 2)} #{symbol}"
  end

  defp country_name("ES"), do: "Spain"
  defp country_name("MX"), do: "Mexico"
  defp country_name("CO"), do: "Colombia"
  defp country_name(c), do: c

  defp status_color(status) do
    case status do
      "pending" -> "bg-yellow-100 text-yellow-800"
      "validating" -> "bg-blue-100 text-blue-800"
      "approved" -> "bg-green-100 text-green-800"
      "rejected" -> "bg-red-100 text-red-800"
      "review_required" -> "bg-orange-100 text-orange-800"
      "cancelled" -> "bg-gray-100 text-gray-800"
      "disbursed" -> "bg-purple-100 text-purple-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp risk_color(nil), do: "text-gray-400"
  defp risk_color(score) do
    cond do
      Decimal.compare(score, Decimal.new("0.7")) == :gt -> "text-green-600"
      Decimal.compare(score, Decimal.new("0.4")) == :gt -> "text-yellow-600"
      true -> "text-red-600"
    end
  end

  defp transition_button_color(status) do
    case status do
      "approved" -> "bg-green-100 hover:bg-green-200 text-green-800"
      "rejected" -> "bg-red-100 hover:bg-red-200 text-red-800"
      "validating" -> "bg-blue-100 hover:bg-blue-200 text-blue-800"
      "cancelled" -> "bg-gray-100 hover:bg-gray-200 text-gray-800"
      "disbursed" -> "bg-purple-100 hover:bg-purple-200 text-purple-800"
      _ -> "bg-gray-100 hover:bg-gray-200 text-gray-700"
    end
  end
end
