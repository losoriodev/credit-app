defmodule CreditApp.Resilience.CircuitBreaker do
  @moduledoc """
  ETS-based circuit breaker with three states: closed, open, half_open.

  - closed: requests pass through normally; failures are counted
  - open: requests are immediately rejected; resets after timeout
  - half_open: one test request is allowed; success closes, failure re-opens
  """
  use GenServer
  require Logger

  @table :circuit_breaker_state
  @default_threshold 5
  @default_reset_timeout_ms 30_000

  # --- Public API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Execute a function through the circuit breaker for the given service."
  def call(service, fun, opts \\ []) do
    threshold = Keyword.get(opts, :threshold, @default_threshold)
    reset_timeout = Keyword.get(opts, :reset_timeout, @default_reset_timeout_ms)

    case get_state(service) do
      :open ->
        if reset_timeout_expired?(service, reset_timeout) do
          set_state(service, :half_open)
          try_call(service, fun, threshold, reset_timeout)
        else
          {:error, :circuit_open}
        end

      :half_open ->
        try_call(service, fun, threshold, reset_timeout)

      :closed ->
        try_call(service, fun, threshold, reset_timeout)
    end
  end

  @doc "Get current state for a service."
  def get_state(service) do
    case :ets.lookup(@table, {:state, service}) do
      [{_, state}] -> state
      [] -> :closed
    end
  end

  @doc "Get current failure count for a service."
  def failure_count(service) do
    case :ets.lookup(@table, {:failures, service}) do
      [{_, count}] -> count
      [] -> 0
    end
  end

  @doc "Reset a circuit breaker to closed state."
  def reset(service) do
    set_state(service, :closed)
    :ets.insert(@table, {{:failures, service}, 0})
    :ets.delete(@table, {:opened_at, service})
    :ok
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_opts) do
    table = :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{table: table}}
  end

  # --- Private ---

  defp try_call(service, fun, threshold, _reset_timeout) do
    try do
      case fun.() do
        {:ok, _} = result ->
          record_success(service)
          result

        {:error, _} = error ->
          record_failure(service, threshold)
          error

        :ok ->
          record_success(service)
          :ok

        other ->
          record_success(service)
          other
      end
    rescue
      exception ->
        record_failure(service, threshold)
        reraise exception, __STACKTRACE__
    end
  end

  defp record_success(service) do
    set_state(service, :closed)
    :ets.insert(@table, {{:failures, service}, 0})
    :ets.delete(@table, {:opened_at, service})
  end

  defp record_failure(service, threshold) do
    count =
      case :ets.lookup(@table, {:failures, service}) do
        [{_, c}] -> c + 1
        [] -> 1
      end

    :ets.insert(@table, {{:failures, service}, count})

    if count >= threshold do
      Logger.warning("[CircuitBreaker] Service #{service} tripped after #{count} failures")
      set_state(service, :open)
      :ets.insert(@table, {{:opened_at, service}, System.monotonic_time(:millisecond)})
    end
  end

  defp set_state(service, state) do
    :ets.insert(@table, {{:state, service}, state})
  end

  defp reset_timeout_expired?(service, reset_timeout) do
    case :ets.lookup(@table, {:opened_at, service}) do
      [{_, opened_at}] ->
        System.monotonic_time(:millisecond) - opened_at >= reset_timeout

      [] ->
        true
    end
  end
end
