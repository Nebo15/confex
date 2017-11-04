defmodule Confex.Type do
  @moduledoc """
  This module is responsible for Confex type-casting.
  """
  @type value :: String.t() | nil
  @type t ::
          :string
          | :integer
          | :float
          | :boolean
          | :atom
          | :module
          | :list
          | {module :: module, function :: atom, additional_arguments :: list}

  @boolean_true ["true", "1", "yes"]
  @boolean_false ["false", "0", "no"]
  @list_separator ","

  @doc """
  Parse string and cast it to Elixir type.
  """
  @spec cast(value :: value, type :: t()) :: {:ok, any()} | {:error, String.t()}
  def cast(nil, _type) do
    {:ok, nil}
  end

  def cast(value, :string) do
    {:ok, value}
  end

  def cast(value, :module) do
    {:ok, Module.concat([value])}
  end

  def cast(value, :integer) do
    case Integer.parse(value) do
      {integer, ""} ->
        {:ok, integer}

      {_integer, remainder_of_binary} ->
        reason = "can not cast #{inspect(value)} to Integer, result contains binary remainder #{remainder_of_binary}"
        {:error, reason}

      :error ->
        {:error, "can not cast #{inspect(value)} to Integer"}
    end
  end

  def cast(value, :float) do
    case Float.parse(value) do
      {float, ""} ->
        {:ok, float}

      {_float, remainder_of_binary} ->
        reason = "can not cast #{inspect(value)} to Float, result contains binary remainder #{remainder_of_binary}"
        {:error, reason}

      :error ->
        {:error, "can not cast #{inspect(value)} to Float"}
    end
  end

  def cast(value, :atom) do
    result =
      value
      |> String.to_charlist()
      |> List.to_atom()

    {:ok, result}
  end

  def cast(value, :boolean) do
    downcased_value = String.downcase(value)

    cond do
      Enum.member?(@boolean_true, downcased_value) ->
        {:ok, true}

      Enum.member?(@boolean_false, downcased_value) ->
        {:ok, false}

      true ->
        reason =
          "can not cast #{inspect(value)} to boolean, expected values are 'true', 'false', '1', '0', 'yes' or 'no'"

        {:error, reason}
    end
  end

  def cast(value, :list) do
    result =
      value
      |> String.split(@list_separator)
      |> Enum.map(&String.trim/1)

    {:ok, result}
  end

  def cast(value, {module, function, additional_arguments}) do
    case apply(module, function, [value] ++ additional_arguments) do
      {:ok, value} ->
        {:ok, value}

      {:error, reason} ->
        {:error, reason}

      other_return ->
        arity = length(additional_arguments) + 1

        reason =
          "expected `#{module}.#{function}/#{arity}` to return " <>
            "either `{:ok, value}` or `{:error, reason}` tuple, got: `#{inspect(other_return)}`"

        {:error, reason}
    end
  end
end
