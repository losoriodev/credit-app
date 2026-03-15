defmodule CreditApp.Applications.CreditApplication do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_countries ~w(ES MX CO PT IT BR)
  @valid_statuses ~w(pending validating approved rejected review_required cancelled disbursed)

  schema "credit_applications" do
    field :country, :string
    field :full_name, :string
    field :identity_document, :string
    field :amount, :decimal
    field :monthly_income, :decimal
    field :application_date, :date
    field :status, :string, default: "pending"
    field :bank_info, :map, default: %{}
    field :risk_score, :decimal
    field :notes, :string
    field :metadata, :map, default: %{}
    field :lock_version, :integer, default: 1

    belongs_to :user, CreditApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def countries, do: @valid_countries
  def statuses, do: @valid_statuses

  def changeset(application, attrs) do
    application
    |> cast(attrs, [
      :country, :full_name, :identity_document, :amount,
      :monthly_income, :application_date, :status, :bank_info,
      :risk_score, :notes, :metadata, :user_id
    ])
    |> validate_required([:country, :full_name, :identity_document, :amount, :monthly_income])
    |> validate_inclusion(:country, @valid_countries)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:monthly_income, greater_than: 0)
    |> foreign_key_constraint(:user_id)
    |> check_constraint(:country, name: :valid_country)
    |> check_constraint(:status, name: :valid_status)
    |> check_constraint(:amount, name: :positive_amount)
    |> check_constraint(:monthly_income, name: :positive_income)
    |> maybe_set_application_date()
  end

  def status_changeset(application, attrs) do
    application
    |> cast(attrs, [:status, :notes, :risk_score, :bank_info, :metadata])
    |> validate_inclusion(:status, @valid_statuses)
    |> check_constraint(:status, name: :valid_status)
    |> optimistic_lock(:lock_version)
  end

  defp maybe_set_application_date(changeset) do
    case get_field(changeset, :application_date) do
      nil -> put_change(changeset, :application_date, Date.utc_today())
      _ -> changeset
    end
  end
end
