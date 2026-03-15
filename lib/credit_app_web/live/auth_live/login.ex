defmodule CreditAppWeb.AuthLive.Login do
  use CreditAppWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    if session["current_user_id"] do
      {:ok, push_navigate(socket, to: ~p"/")}
    else
      {:ok,
       socket
       |> assign(:page_title, "Login")
       |> assign(:error, nil)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="max-w-md w-full space-y-8">
        <div class="text-center">
          <h1 class="text-4xl font-bold text-gray-900">CreditApp</h1>
          <p class="mt-2 text-sm text-gray-600">Multi-Country Credit Application System</p>
        </div>

        <div class="bg-white py-8 px-6 shadow-lg rounded-lg">
          <h2 class="text-2xl font-bold text-gray-900 mb-6">Sign in</h2>

          <div :if={@flash["error"]} class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {@flash["error"]}
          </div>

          <form action={~p"/auth/session"} method="post" class="space-y-5">
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input type="email" name="email"
                class="w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="admin@creditapp.com" required autofocus />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input type="password" name="password"
                class="w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="admin123456" required />
            </div>

            <button type="submit"
              class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-lg shadow transition">
              Sign in
            </button>
          </form>

          <div class="mt-6 border-t pt-4">
            <p class="text-xs text-gray-500 mb-2">Test credentials:</p>
            <div class="space-y-1 text-xs text-gray-500">
              <p><span class="font-medium">Admin:</span> admin@creditapp.com / admin123456</p>
              <p><span class="font-medium">Analyst ES:</span> analyst_es@creditapp.com / analyst123456</p>
              <p><span class="font-medium">Analyst MX:</span> analyst_mx@creditapp.com / analyst123456</p>
              <p><span class="font-medium">Viewer:</span> viewer@creditapp.com / viewer123456</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
