# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :credit_app,
  ecto_repos: [CreditApp.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :credit_app, CreditAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CreditAppWeb.ErrorHTML, json: CreditAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CreditApp.PubSub,
  live_view: [signing_salt: "AgsqVTAF"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :credit_app, CreditApp.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  credit_app: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  credit_app: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Oban job queue
config :credit_app, Oban,
  repo: CreditApp.Repo,
  queues: [
    default: 10,
    risk_assessment: 5,
    webhooks: 5,
    audit: 5,
    banking: 5
  ]

# Guardian JWT
config :credit_app, CreditApp.Accounts.Guardian,
  issuer: "credit_app",
  secret_key: "dev_secret_key_change_in_production_please_1234567890"

# Cachex
config :credit_app, :cache_ttl, 300_000

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :country, :application_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
