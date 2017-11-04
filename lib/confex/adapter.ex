defmodule Confex.Adapter do
  @moduledoc """
  This module provides behaviour for the Confex adapters, that are responsible
  for fetching raw values from an environment variable or other source.

  By default, Confex is supplied with two adapters:

    * `:system` - read configuration from system environment (`Confex.Adapters.SystemEnvironment`);
    * `:system_file` - read file path from system environment and \
    read configuration from this file (`Confex.Adapters.SystemEnvironment`).

  To simplify configuration syntax, Confex allows to have an alias for adapter names.
  """

  @doc """
  Fetch raw configuration value.
  """
  @callback fetch_value(key :: String.t()) :: {:ok, String.t()} | :error

  @doc false
  # Resolve adapter with shorthand for built-in's.
  def to_module(:system), do: Confex.Adapters.SystemEnvironment
  def to_module(:system_file), do: Confex.Adapters.SystemEnvironment
end
