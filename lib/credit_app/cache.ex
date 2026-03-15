defmodule CreditApp.Cache do
  @moduledoc """
  Cache wrapper around Cachex.
  Used for caching credit application reads and listing results.
  Strategy: write-through invalidation on mutations.
  """

  @cache_name :credit_app_cache
  @default_ttl :timer.minutes(5)

  def get(key) do
    case Cachex.get(@cache_name, key) do
      {:ok, nil} -> {:miss, nil}
      {:ok, value} -> {:hit, value}
      _ -> {:miss, nil}
    end
  end

  def put(key, value, ttl \\ @default_ttl) do
    Cachex.put(@cache_name, key, value, ttl: ttl)
    value
  end

  def delete(key) do
    Cachex.del(@cache_name, key)
  end

  def invalidate_application(id) do
    delete("application:#{id}")
    :ok
  end

  def invalidate_listing(country) do
    delete("applications:#{country}")
    delete("applications:all")
    :ok
  end

  def fetch(key, ttl \\ @default_ttl, fun) do
    case get(key) do
      {:hit, value} ->
        value

      {:miss, _} ->
        value = fun.()
        put(key, value, ttl)
        value
    end
  end
end
