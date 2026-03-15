defmodule CreditAppWeb.Router do
  use CreditAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CreditAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :api_auth do
    plug CreditApp.Accounts.AuthPipeline
  end

  # --- Login (public) ---
  scope "/", CreditAppWeb do
    pipe_through :browser

    live "/login", AuthLive.Login, :login

    # Session controller (HTTP - not LiveView)
    post "/auth/session", SessionController, :create
    delete "/auth/session", SessionController, :delete
  end

  # --- Protected LiveView Frontend ---
  scope "/", CreditAppWeb do
    pipe_through :browser

    live_session :authenticated, on_mount: {CreditAppWeb.AuthHooks, :require_auth} do
      live "/", ApplicationLive.Index, :index
      live "/applications/new", ApplicationLive.New, :new
      live "/applications/:id", ApplicationLive.Show, :show
    end
  end

  # --- Public API (no auth) ---
  scope "/api", CreditAppWeb.Api do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login

    # Webhook endpoint (secured by webhook secret in production)
    post "/webhooks/receive", WebhookController, :receive
  end

  # --- Protected API ---
  scope "/api", CreditAppWeb.Api do
    pipe_through [:api, :api_auth]

    get "/auth/me", AuthController, :me

    resources "/applications", CreditApplicationController, only: [:index, :create, :show]
    put "/applications/:id/status", CreditApplicationController, :update_status
  end

  # Dev routes
  if Application.compile_env(:credit_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CreditAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
