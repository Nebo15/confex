defmodule Confex.Adapters.SystemEnvironment do
  @moduledoc """
  Adapter to fetch values from system environment variables.
  """
  @behaviour Confex.Adapter

  @doc """
  Fetch value from environment variable.

  ## Example

      iex> :ok = System.delete_env("SOME_TEST_ENV")
      ...> :error = #{__MODULE__}.fetch_value("SOME_TEST_ENV")
      ...> :ok = System.put_env("SOME_TEST_ENV", "some_value")
      ...> {:ok, "some_value"} = #{__MODULE__}.fetch_value("SOME_TEST_ENV")
      {:ok, "some_value"}
  """
  def fetch_value(key) do
    case System.get_env(key) do
      nil -> :error
      value -> {:ok, value}
    end
  end
end
