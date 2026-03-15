defmodule CreditApp.Applications do
  @moduledoc "Main context for credit applications."
  import Ecto.Query
  require Logger

  alias Ecto.Multi
  alias CreditApp.Repo
  alias CreditApp.Applications.{CreditApplication, StateMachine}
  alias CreditApp.Countries.Registry, as: CountryRegistry
  alias CreditApp.Cache

  # --- Creation ---

  def create_application(attrs) do
    country = attrs["country"] || attrs[:country]

    with :ok <- validate_country(country, attrs) do
      changeset = CreditApplication.changeset(%CreditApplication{}, attrs)

      Multi.new()
      |> Multi.insert(:application, changeset)
      |> Oban.insert(:bank_info_job, fn %{application: app} ->
        CreditApp.Workers.BankInfoWorker.new(%{
          id: app.id,
          country: country,
          document: app.identity_document
        })
      end)
      |> Oban.insert(:audit_job, fn %{application: app} ->
        CreditApp.Workers.AuditWorker.new(%{
          entity_type: "credit_application",
          entity_id: app.id,
          action: "created"
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{application: application}} ->
          Logger.info("[Applications] Created application #{application.id} for #{country}")
          :telemetry.execute(
            [:credit_app, :application, :created],
            %{count: 1},
            %{country: country}
          )
          Cache.invalidate_listing(country)
          {:ok, application}

        {:error, :application, changeset, _} ->
          {:error, changeset}

        {:error, _step, reason, _} ->
          {:error, reason}
      end
    end
  end

  # --- Read ---

  def get_application(id) do
    Cache.fetch("application:#{id}", :timer.minutes(5), fn ->
      CreditApplication
      |> Repo.get(id)
      |> Repo.preload(:user)
    end)
  end

  def get_application!(id) do
    CreditApplication
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  # --- List ---

  def list_applications(filters \\ %{}) do
    CreditApplication
    |> apply_filters(filters)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"country", country}, q when country != "" ->
        where(q, [a], a.country == ^country)

      {"status", status}, q when status != "" ->
        where(q, [a], a.status == ^status)

      {"from_date", date}, q when date != "" ->
        where(q, [a], a.application_date >= ^date)

      {"to_date", date}, q when date != "" ->
        where(q, [a], a.application_date <= ^date)

      {"min_amount", amount}, q when amount != "" ->
        where(q, [a], a.amount >= ^Decimal.new(amount))

      {"max_amount", amount}, q when amount != "" ->
        where(q, [a], a.amount <= ^Decimal.new(amount))

      _, q ->
        q
    end)
  end

  # --- Update Status ---

  def update_status(id, new_status, opts \\ []) do
    application = get_application!(id)

    with {:ok, _status} <- StateMachine.transition(application, new_status) do
      changeset =
        application
        |> CreditApplication.status_changeset(%{
          status: new_status,
          notes: Keyword.get(opts, :notes)
        })

      Multi.new()
      |> Multi.update(:application, changeset)
      |> Oban.insert(:audit_job, fn _changes ->
        CreditApp.Workers.AuditWorker.new(%{
          entity_type: "credit_application",
          entity_id: id,
          action: "status_changed",
          changes: %{from: application.status, to: new_status},
          metadata: %{actor_id: Keyword.get(opts, :actor_id)}
        })
      end)
      |> Oban.insert(:webhook_job, fn _changes ->
        CreditApp.Workers.WebhookWorker.new(%{
          application_id: id,
          event: "status_changed",
          data: %{from: application.status, to: new_status}
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{application: updated}} ->
          Logger.info("[Applications] Status updated: #{id} -> #{new_status}")
          :telemetry.execute(
            [:credit_app, :application, :status_changed],
            %{count: 1},
            %{from: application.status, to: new_status}
          )
          Cache.invalidate_application(id)
          Cache.invalidate_listing(updated.country)
          broadcast_change(id, updated.country, new_status)
          {:ok, updated}

        {:error, :application, changeset, _} ->
          {:error, changeset}

        {:error, _step, reason, _} ->
          {:error, reason}
      end
    end
  end

  # --- Update bank info ---

  def update_bank_info(id, bank_info) do
    application = get_application!(id)

    application
    |> CreditApplication.status_changeset(%{bank_info: bank_info})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        Cache.invalidate_application(id)
        {:ok, updated}

      {:error, _} = error ->
        error
    end
  end

  # --- Update risk score ---

  def update_risk_score(id, score) do
    application = get_application!(id)

    application
    |> CreditApplication.status_changeset(%{risk_score: score})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        Cache.invalidate_application(id)
        {:ok, updated}

      {:error, _} = error ->
        error
    end
  end

  # --- Private ---

  defp validate_country(country, attrs) do
    case CountryRegistry.validate(country, attrs) do
      :ok ->
        :ok

      {:error, reason} = error ->
        CreditApp.Audit.log("credit_application", nil, "validation_failed",
          %{country: country, reason: reason},
          metadata: %{document: attrs["identity_document"] || attrs[:identity_document]})
        error
    end
  end

  defp broadcast_change(id, country, status) do
    payload = {:application_changed, %{id: id, operation: "STATUS_UPDATE", country: country, status: status}}

    Phoenix.PubSub.broadcast(CreditApp.PubSub, "applications:#{country}", payload)
    Phoenix.PubSub.broadcast(CreditApp.PubSub, "application:#{id}", payload)
  end
end
