defmodule Confex.Adapters.FileFromSystemEnvironment do
  @moduledoc """
  Adapter that resolves Confex values from file which path is specified in an environment variable.
  """
  @behaviour Confex.Adapter

  @doc """
  Fetch value from file which path is specified in an environment variable
  and trim trailing newline it in it's content.

  ## Example

      iex> :ok = System.delete_env("SOME_TEST_FILE")
      ...> :error = #{__MODULE__}.fetch_value("SOME_TEST_FILE")
      ...> :ok = System.put_env("SOME_TEST_FILE", "test/fixtures/file_secret.txt")
      ...> {:ok, "foo_bar"} = #{__MODULE__}.fetch_value("SOME_TEST_FILE")
      {:ok, "foo_bar"}
  """
  def fetch_value(key) do
    case System.get_env(key) do
      nil -> :error
      path -> read_value(path)
    end
  end

  defp read_value(path) do
    case File.read(path) do
      {:ok, value} -> {:ok, String.trim_trailing(value, "\n")}
      _ -> :error
    end
  end
end
