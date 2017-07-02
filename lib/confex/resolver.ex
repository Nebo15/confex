defmodule Confex.Resolver do
  @moduledoc """
  This module provides API to recursively resolve Confex configuration types in a `Map` or `Keyword` via
  one of `Confex.Adpater`'s.
  """
  alias Confex.Adapter
  alias Confex.Type

  @types [:string, :integer, :float, :boolean, :atom, :module, :list]

  # If you are distributing new adapter for Confex,
  # please contribute additional value to this list.
  @adapters Application.get_env(:confex, :adapters, [:system, Confex.Adapters.SystemEnvironment])

  @doc """
  Resolves all configuration tuples via adapters.

  Can be used when values are stored not in Application environment.

  ## Example

      iex> #{__MODULE__}.resolve(nil)
      {:ok, nil}

      iex> :ok = System.delete_env("SOME_TEST_ENV")
      ...> {:error, {:unresolved, _message}} = #{__MODULE__}.resolve([test: {:system, "DOES_NOT_EXIST"}])
      ...> :ok = System.put_env("SOME_TEST_ENV", "some_value")
      ...> #{__MODULE__}.resolve([test: {:system, "SOME_TEST_ENV", "defaults"}])
      {:ok, [test: "some_value"]}

      iex> #{__MODULE__}.resolve([test: {:system, "DOES_NOT_EXIST", "defaults"}])
      {:ok, [test: "defaults"]}
  """
  @spec resolve(config :: any()) :: {:ok, any()} | {:error, any()}
  def resolve(nil),
    do: {:ok, nil}
  def resolve(config) when is_list(config) do
    case Enum.reduce_while(config, [], &reduce_list/2) do
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  end
  def resolve(config) when is_map(config) do
    case Enum.reduce_while(config, %{}, &reduce_map/2) do
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  end
  def resolve(config),
    do: resolve_value(config)

  @doc """
  Same as `resolve/1` but will raise `ArgumentError` if one of configuration tuples can not be resolved.
  """
  @spec resolve!(config :: any()) :: any() | no_return
  def resolve!(config) do
    case resolve(config) do
      {:ok, config} -> config
      {:error, {_reason, message}} ->
        raise ArgumentError, message
    end
  end

  defp reduce_map({key, nil}, acc),
    do: {:cont, Map.put(acc, key, nil)}
  defp reduce_map({key, list}, acc) when is_list(list) do
    case Enum.reduce_while(list, [], &reduce_list/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, Map.put(acc, key, result)}
    end
  end
  defp reduce_map({key, map}, acc) when is_map(map) do
    case Enum.reduce_while(map, %{}, &reduce_map/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, Map.put(acc, key, result)}
    end
  end
  defp reduce_map({key, value}, acc) do
    case resolve_value(value) do
      {:ok, value} -> {:cont, Map.put(acc, key, value)}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp reduce_list({key, nil}, acc),
    do: {:cont, {key, nil} ++ acc}
  defp reduce_list({key, list}, acc) when is_list(list) do
    case Enum.reduce_while(list, [], &reduce_list/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, acc ++ [{key, result}]}
    end
  end
  defp reduce_list({key, map}, acc) when is_map(map) do
    case Enum.reduce_while(map, %{}, &reduce_map/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, acc ++ [{key, result}]}
    end
  end
  defp reduce_list({key, value}, acc) when is_tuple(value) do
    case resolve_value(value) do
      {:ok, value} -> {:cont, acc ++ [{key, value}]}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end
  defp reduce_list(value, acc),
    do: {:cont, acc ++ [value]}

  defp resolve_value({adapter, type, key, default_value}) when adapter in @adapters and type in @types do
    with adapter <- Adapter.to_module(adapter),
         {:ok, value} <- adapter.fetch_value(key),
         {:ok, value} <- Type.cast(value, type) do
      {:ok, value}
    else
      {:error, reason} -> {:error, {:invalid, reason}}
      :error -> {:ok, default_value}
    end
  end
  defp resolve_value({adapter, type, key}) when adapter in @adapters and type in @types do
    adapter_mod = Adapter.to_module(adapter)
    with {:ok, value} <- adapter_mod.fetch_value(key),
         {:ok, value} <- Type.cast(value, type) do
      {:ok, value}
    else
      {:error, reason} -> {:error, {:invalid, reason}}
      :error -> {:error, {:unresolved, "can not resolve key #{key} value via adapter #{to_string(adapter_mod)}"}}
    end
  end
  defp resolve_value({adapter, key, default_value}) when adapter in @adapters,
    do: resolve_value({adapter, :string, key, default_value})
  defp resolve_value({adapter, key}) when adapter in @adapters,
    do: resolve_value({adapter, :string, key})
  defp resolve_value(value),
    do: {:ok, value}
end
