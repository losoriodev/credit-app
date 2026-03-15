defmodule CreditAppWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      sum("phoenix.socket_drain.count"),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("credit_app.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("credit_app.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("credit_app.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("credit_app.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("credit_app.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Custom Business Metrics
      counter("credit_app.application.created.count",
        tags: [:country],
        description: "Number of credit applications created"
      ),
      counter("credit_app.application.status_changed.count",
        tags: [:from, :to],
        description: "Number of status transitions"
      ),
      summary("credit_app.risk.score_calculated.value",
        tags: [:country],
        description: "Distribution of risk scores by country"
      ),
      summary("credit_app.provider.call.duration",
        tags: [:provider],
        unit: {:native, :millisecond},
        description: "Banking provider call duration"
      ),
      counter("credit_app.provider.call.error.count",
        tags: [:provider],
        description: "Banking provider call errors"
      ),

      # Oban Job Metrics
      counter("oban.job.start.count",
        tags: [:queue, :worker],
        description: "Oban jobs started"
      ),
      counter("oban.job.stop.count",
        tags: [:queue, :worker],
        description: "Oban jobs completed"
      ),
      counter("oban.job.exception.count",
        tags: [:queue, :worker],
        description: "Oban jobs with exceptions"
      ),

      # Periodic application stats
      last_value("credit_app.applications.total.count",
        description: "Total number of applications"
      ),
      last_value("credit_app.applications.pending.count",
        description: "Number of pending applications"
      ),
      last_value("credit_app.applications.validating.count",
        description: "Number of validating applications"
      )
    ]
  end

  defp periodic_measurements do
    [
      {__MODULE__, :measure_application_stats, []}
    ]
  end

  def measure_application_stats do
    import Ecto.Query

    try do
      total =
        CreditApp.Applications.CreditApplication
        |> CreditApp.Repo.aggregate(:count, :id)

      pending =
        CreditApp.Applications.CreditApplication
        |> where([a], a.status == "pending")
        |> CreditApp.Repo.aggregate(:count, :id)

      validating =
        CreditApp.Applications.CreditApplication
        |> where([a], a.status == "validating")
        |> CreditApp.Repo.aggregate(:count, :id)

      :telemetry.execute([:credit_app, :applications, :total], %{count: total}, %{})
      :telemetry.execute([:credit_app, :applications, :pending], %{count: pending}, %{})
      :telemetry.execute([:credit_app, :applications, :validating], %{count: validating}, %{})
    rescue
      _ -> :ok
    end
  end
end
