defmodule CreditAppWeb.ApplicationLive.New do
  use CreditAppWeb, :live_view

  alias CreditApp.Applications
  alias CreditApp.Applications.CreditApplication

  @impl true
  def mount(_params, _session, socket) do
    changeset = CreditApplication.changeset(%CreditApplication{}, %{})

    {:ok,
     socket
     |> assign(:page_title, "New Credit Application")
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_event("validate", %{"credit_application" => params}, socket) do
    changeset =
      %CreditApplication{}
      |> CreditApplication.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"credit_application" => params}, socket) do
    case Applications.create_application(params) do
      {:ok, application} ->
        {:noreply,
         socket
         |> put_flash(:info, "Application created successfully!")
         |> push_navigate(to: ~p"/applications/#{application.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, :error_message, message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <div class="mb-6">
        <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-800">&larr; Back to list</.link>
      </div>

      <h1 class="text-3xl font-bold text-gray-900 mb-8">New Credit Application</h1>

      <div :if={@error_message} class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
        {@error_message}
      </div>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Country *</label>
          <select name="credit_application[country]" class="w-full rounded-lg border-gray-300 shadow-sm" required>
            <option value="">Select country...</option>
            <option value="ES" selected={@form[:country].value == "ES"}>Spain (ES) - DNI required</option>
            <option value="MX" selected={@form[:country].value == "MX"}>Mexico (MX) - CURP required</option>
            <option value="CO" selected={@form[:country].value == "CO"}>Colombia (CO) - CC required</option>
          </select>
          <p :for={msg <- get_errors(@form[:country])} class="mt-1 text-sm text-red-600">{msg}</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Full Name *</label>
          <input type="text" name="credit_application[full_name]" value={@form[:full_name].value}
            class="w-full rounded-lg border-gray-300 shadow-sm" placeholder="John Doe" required />
          <p :for={msg <- get_errors(@form[:full_name])} class="mt-1 text-sm text-red-600">{msg}</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Identity Document *</label>
          <input type="text" name="credit_application[identity_document]" value={@form[:identity_document].value}
            class="w-full rounded-lg border-gray-300 shadow-sm" placeholder={doc_placeholder(@form[:country].value)} required />
          <p class="mt-1 text-xs text-gray-500">{doc_hint(@form[:country].value)}</p>
          <p :for={msg <- get_errors(@form[:identity_document])} class="mt-1 text-sm text-red-600">{msg}</p>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Requested Amount *</label>
            <input type="number" name="credit_application[amount]" value={@form[:amount].value}
              class="w-full rounded-lg border-gray-300 shadow-sm" step="0.01" min="0" required />
            <p :for={msg <- get_errors(@form[:amount])} class="mt-1 text-sm text-red-600">{msg}</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Monthly Income *</label>
            <input type="number" name="credit_application[monthly_income]" value={@form[:monthly_income].value}
              class="w-full rounded-lg border-gray-300 shadow-sm" step="0.01" min="0" required />
            <p :for={msg <- get_errors(@form[:monthly_income])} class="mt-1 text-sm text-red-600">{msg}</p>
          </div>
        </div>

        <div>
          <button type="submit"
            class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-lg shadow">
            Submit Application
          </button>
        </div>
      </.form>
    </div>
    """
  end

  defp get_errors(field) do
    case field do
      %{errors: errors} -> Enum.map(errors, fn {msg, _} -> msg end)
      _ -> []
    end
  end

  defp doc_placeholder("ES"), do: "12345678Z"
  defp doc_placeholder("MX"), do: "BADD110313HCMLNS09"
  defp doc_placeholder("CO"), do: "1234567890"
  defp doc_placeholder(_), do: "Select a country first"

  defp doc_hint("ES"), do: "Spanish DNI: 8 digits + 1 control letter"
  defp doc_hint("MX"), do: "Mexican CURP: 18 alphanumeric characters"
  defp doc_hint("CO"), do: "Colombian CC: 6 to 10 digits"
  defp doc_hint(_), do: ""
end
