defmodule CreditApp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CreditAppWeb.Telemetry,
      CreditApp.Repo,
      {DNSCluster, query: Application.get_env(:credit_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CreditApp.PubSub},
      {Oban, Application.fetch_env!(:credit_app, Oban)},
      {Cachex, name: :credit_app_cache},
      CreditApp.Repo.Listener,
      CreditAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CreditApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CreditAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
