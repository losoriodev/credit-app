defmodule CreditApp.Workers.RiskAssessmentWorker do
  @moduledoc """
  Async worker that performs risk assessment on a credit application.
  Triggered by PostgreSQL NOTIFY after insert.
  """
  use Oban.Worker,
    queue: :risk_assessment,
    max_attempts: 3,
    unique: [period: 60, fields: [:args], keys: [:id]]

  require Logger
  alias CreditApp.Applications
  alias CreditApp.Countries.Registry

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Logger.info("[RiskAssessmentWorker] Starting risk assessment for application #{id}")

    application = Applications.get_application!(id)

    with {:ok, country_module} <- Registry.get_module(application.country) do
      score = calculate_risk_score(application, country_module)
      Logger.info("[RiskAssessmentWorker] Score for #{id}: #{score}")

      {:ok, _} = Applications.update_risk_score(id, score)

      new_status = determine_status(country_module, application, score)

      case application.status do
        "validating" ->
          Applications.update_status(id, new_status, notes: "Auto-assessed by risk engine")

        _ ->
          Logger.info("[RiskAssessmentWorker] Skipping status update, current: #{application.status}")
      end

      :ok
    end
  end

  defp determine_status(country_module, application, score) do
    review_attrs = %{
      amount: application.amount,
      monthly_income: application.monthly_income,
      bank_info: application.bank_info
    }

    cond do
      country_module.requires_additional_review?(review_attrs) ->
        "review_required"

      Decimal.compare(score, Decimal.new("0.6")) == :gt ->
        "approved"

      true ->
        "rejected"
    end
  end

  defp calculate_risk_score(application, _country_module) do
    income = application.monthly_income
    amount = application.amount

    ratio = Decimal.div(amount, Decimal.max(income, Decimal.new(1)))

    base_score =
      cond do
        Decimal.compare(ratio, Decimal.new(1)) == :lt -> Decimal.new("0.9")
        Decimal.compare(ratio, Decimal.new(2)) == :lt -> Decimal.new("0.8")
        Decimal.compare(ratio, Decimal.new(3)) == :lt -> Decimal.new("0.7")
        Decimal.compare(ratio, Decimal.new(4)) == :lt -> Decimal.new("0.5")
        Decimal.compare(ratio, Decimal.new(5)) == :lt -> Decimal.new("0.3")
        true -> Decimal.new("0.1")
      end

    bank_bonus = extract_bank_score(application.bank_info)

    # weighted: 60% income ratio + 40% bank score
    weighted_base = Decimal.mult(base_score, Decimal.new("0.6"))
    weighted_bank = Decimal.mult(bank_bonus, Decimal.new("0.4"))

    Decimal.add(weighted_base, weighted_bank)
    |> Decimal.min(Decimal.new(1))
    |> Decimal.max(Decimal.new(0))
    |> Decimal.round(4)
  end

  defp extract_bank_score(%{"credit_score" => cs}) when is_integer(cs),
    do: Decimal.div(Decimal.new(cs), Decimal.new(1000))

  defp extract_bank_score(%{"score_bc" => cs}) when is_integer(cs),
    do: Decimal.div(Decimal.new(cs), Decimal.new(1000))

  defp extract_bank_score(%{"score" => cs}) when is_integer(cs),
    do: Decimal.div(Decimal.new(cs), Decimal.new(1000))

  defp extract_bank_score(_), do: Decimal.new(0)
end
