defmodule CreditAppWeb.ApplicationLive.Index do
  use CreditAppWeb, :live_view

  alias CreditApp.Applications

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      for country <- CreditApp.Countries.Registry.supported_countries() do
        Phoenix.PubSub.subscribe(CreditApp.PubSub, "applications:#{country}")
      end
    end

    applications = Applications.list_applications()

    {:ok,
     socket
     |> assign(:page_title, "Credit Applications")
     |> assign(:applications, applications)
     |> assign(:country_filter, "")
     |> assign(:status_filter, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    filters = %{
      "country" => params["country"] || "",
      "status" => params["status"] || ""
    }

    applications = Applications.list_applications(filters)

    {:noreply,
     socket
     |> assign(:applications, applications)
     |> assign(:country_filter, filters["country"])
     |> assign(:status_filter, filters["status"])}
  end

  @impl true
  def handle_event("filter", %{"country" => country, "status" => status}, socket) do
    params =
      %{}
      |> then(fn p -> if country != "", do: Map.put(p, "country", country), else: p end)
      |> then(fn p -> if status != "", do: Map.put(p, "status", status), else: p end)

    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
  end

  @impl true
  def handle_info({:application_changed, _payload}, socket) do
    filters = %{
      "country" => socket.assigns.country_filter,
      "status" => socket.assigns.status_filter
    }

    applications = Applications.list_applications(filters)
    {:noreply, assign(socket, :applications, applications)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Credit Applications</h1>
          <p class="text-sm text-gray-500 mt-1">
            Logged in as <span class="font-medium">{@current_user.email}</span>
            <span class={"ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{role_badge(@current_role)}"}>
              {@current_role}
            </span>
            <.link href={~p"/auth/session"} method="delete" class="ml-3 text-red-500 hover:text-red-700 text-xs">
              Logout
            </.link>
          </p>
        </div>
        <.link :if={@current_role in ["admin", "analyst"]} navigate={~p"/applications/new"}
          class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg shadow">
          + New Application
        </.link>
      </div>

      <!-- Filters -->
      <form phx-change="filter" class="mb-6 flex gap-4">
        <select name="country" class="rounded-lg border-gray-300 shadow-sm">
          <option value="">All Countries</option>
          <option value="ES" selected={@country_filter == "ES"}>Spain (ES)</option>
          <option value="MX" selected={@country_filter == "MX"}>Mexico (MX)</option>
          <option value="CO" selected={@country_filter == "CO"}>Colombia (CO)</option>
          <option value="AR" selected={@country_filter == "AR"}>Argentina (AR)</option>
        </select>
        <select name="status" class="rounded-lg border-gray-300 shadow-sm">
          <option value="">All Statuses</option>
          <option value="pending" selected={@status_filter == "pending"}>Pending</option>
          <option value="validating" selected={@status_filter == "validating"}>Validating</option>
          <option value="approved" selected={@status_filter == "approved"}>Approved</option>
          <option value="rejected" selected={@status_filter == "rejected"}>Rejected</option>
          <option value="review_required" selected={@status_filter == "review_required"}>Review Required</option>
          <option value="cancelled" selected={@status_filter == "cancelled"}>Cancelled</option>
          <option value="disbursed" selected={@status_filter == "disbursed"}>Disbursed</option>
        </select>
      </form>

      <!-- Real-time indicator -->
      <div class="mb-4 text-sm text-green-600 flex items-center gap-2">
        <span class="relative flex h-3 w-3">
          <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
          <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
        </span>
        Live updates enabled
      </div>

      <!-- Applications table -->
      <div class="bg-white shadow-md rounded-lg overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Country</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Risk Score</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr :for={app <- @applications} class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  {app.country}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{app.full_name}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{format_amount(app.amount, app.country)}</td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_color(app.status)}"}>
                  {app.status}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {if app.risk_score, do: Decimal.round(app.risk_score, 2), else: "-"}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{app.application_date}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <.link navigate={~p"/applications/#{app.id}"} class="text-blue-600 hover:text-blue-900">
                  View
                </.link>
              </td>
            </tr>
          </tbody>
        </table>

        <div :if={@applications == []} class="p-8 text-center text-gray-500">
          No applications found.
        </div>
      </div>
    </div>
    """
  end

  defp format_amount(amount, country) do
    symbol =
      case country do
        "ES" -> "EUR"
        "MX" -> "MXN"
        "CO" -> "COP"
        "AR" -> "ARS"
        _ -> ""
      end

    "#{Decimal.round(amount, 2)} #{symbol}"
  end

  defp role_badge("admin"), do: "bg-red-100 text-red-800"
  defp role_badge("analyst"), do: "bg-blue-100 text-blue-800"
  defp role_badge("viewer"), do: "bg-gray-100 text-gray-800"
  defp role_badge(_), do: "bg-gray-100 text-gray-800"

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
end
