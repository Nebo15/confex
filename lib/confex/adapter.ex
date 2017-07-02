defmodule Confex.Adapter do
  @moduledoc """
  This module provides interface for all Confex adapters to resolve configuration by tuples in Application env.
  """

  @doc """
  Fetch configuration value by fetch statement.
  """
  @callback fetch_value(key :: String.t) :: {:ok, String.t} | :error

  @doc false
  # Resolve adapter with shorthand for built-in's.
  def to_module(:system),
    do: Confex.Adapters.SystemEnvironment
end
