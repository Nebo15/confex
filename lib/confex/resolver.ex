defmodule Confex.Resolver do
  @moduledoc """
  This module provides API to recursively resolve system tuples in a `Map` or `Keyword` structures.
  """
  alias Confex.Adapter
  alias Confex.Type

  @known_types [:string, :integer, :float, :boolean, :atom, :module, :list]
  @known_adapter_aliases [:system, :system_file]

  @doc """
  Resolves all system tuples in a structure.

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
  def resolve(nil), do: {:ok, nil}

  def resolve(config) when is_list(config) do
    case Enum.reduce_while(config, [], &reduce_list/2) do
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  end

  def resolve(%{__struct__: _type} = config) do
    {:ok, config}
  end

  def resolve(config) when is_map(config) do
    case Enum.reduce_while(config, %{}, &reduce_map/2) do
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  end

  def resolve(config), do: maybe_resolve_with_adapter(config)

  @doc """
  Same as `resolve/1` but will raise `ArgumentError` if one of system tuples can not be resolved.
  """
  @spec resolve!(config :: any()) :: any() | no_return
  def resolve!(config) do
    case resolve(config) do
      {:ok, config} ->
        config

      {:error, {_reason, message}} ->
        raise ArgumentError, message
    end
  end

  defp reduce_map({key, nil}, acc) do
    {:cont, Map.put(acc, key, nil)}
  end

  defp reduce_map({key, list}, acc) when is_list(list) do
    case Enum.reduce_while(list, [], &reduce_list/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, Map.put(acc, key, result)}
    end
  end

  defp reduce_map({key, %{__struct__: _type} = struct}, acc) do
    {:cont, Map.put(acc, key, struct)}
  end

  defp reduce_map({key, map}, acc) when is_map(map) do
    case Enum.reduce_while(map, %{}, &reduce_map/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, Map.put(acc, key, result)}
    end
  end

  defp reduce_map({key, value}, acc) do
    case maybe_resolve_with_adapter(value) do
      {:ok, value} -> {:cont, Map.put(acc, key, value)}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp reduce_list({key, nil}, acc) do
    {:cont, [{key, nil}] ++ acc}
  end

  defp reduce_list({key, list}, acc) when is_list(list) do
    case Enum.reduce_while(list, [], &reduce_list/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, acc ++ [{key, result}]}
    end
  end

  defp reduce_list({key, %{__struct__: _type} = struct}, acc) do
    {:cont, acc ++ [{key, struct}]}
  end

  defp reduce_list({key, map}, acc) when is_map(map) do
    case Enum.reduce_while(map, %{}, &reduce_map/2) do
      {:error, reason} -> {:halt, {:error, reason}}
      result -> {:cont, acc ++ [{key, result}]}
    end
  end

  defp reduce_list({key, value}, acc) when is_tuple(value) do
    case maybe_resolve_with_adapter(value) do
      {:ok, value} -> {:cont, acc ++ [{key, value}]}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp reduce_list(value, acc) do
    {:cont, acc ++ [value]}
  end

  defp maybe_resolve_with_adapter({{:via, adapter}, type, key, default_value})
       when is_atom(adapter) and (type in @known_types or is_tuple(type)) do
    resolve_value(adapter, type, key, default_value)
  end

  defp maybe_resolve_with_adapter({adapter_alias, type, key, default_value})
       when adapter_alias in @known_adapter_aliases and (type in @known_types or is_tuple(type)) do
    adapter_alias |> Adapter.to_module() |> resolve_value(type, key, default_value)
  end

  defp maybe_resolve_with_adapter({{:via, adapter}, type, key})
       when is_atom(adapter) and (type in @known_types or is_tuple(type)) do
    resolve_value(adapter, type, key)
  end

  defp maybe_resolve_with_adapter({adapter_alias, type, key})
       when adapter_alias in @known_adapter_aliases and (type in @known_types or is_tuple(type)) do
    adapter_alias |> Adapter.to_module() |> resolve_value(type, key)
  end

  defp maybe_resolve_with_adapter({{:via, adapter}, key, default_value})
       when is_atom(adapter) and is_binary(key) do
    resolve_value(adapter, :string, key, default_value)
  end

  defp maybe_resolve_with_adapter({adapter_alias, key, default_value})
       when adapter_alias in @known_adapter_aliases do
    adapter_alias |> Adapter.to_module() |> resolve_value(:string, key, default_value)
  end

  defp maybe_resolve_with_adapter({{:via, adapter}, key})
       when is_atom(adapter) do
    resolve_value(adapter, :string, key)
  end

  defp maybe_resolve_with_adapter({adapter_alias, key})
       when adapter_alias in @known_adapter_aliases do
    adapter_alias |> Adapter.to_module() |> resolve_value(:string, key)
  end

  defp maybe_resolve_with_adapter(value) do
    {:ok, value}
  end

  defp resolve_value(adapter, type, key, default_value) do
    with {:ok, value} <- adapter.fetch_value(key),
         {:ok, value} <- Type.cast(value, type) do
      {:ok, value}
    else
      {:error, reason} -> {:error, {:invalid, reason}}
      :error -> {:ok, default_value}
    end
  end

  defp resolve_value(adapter, type, key) do
    with {:ok, value} <- adapter.fetch_value(key),
         {:ok, value} <- Type.cast(value, type) do
      {:ok, value}
    else
      {:error, reason} ->
        {:error, {:invalid, reason}}

      :error ->
        {
          :error,
          {:unresolved, "can not resolve key #{key} value via adapter #{to_string(adapter)}"}
        }
    end
  end
end
