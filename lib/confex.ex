defmodule Confex do
  @moduledoc """
  This is helper module that provides a nice way to read environment configuration at runtime.
  """

  @doc """
  Fetches a value from the config, or from the environment if {:system, "VAR"} is provided.
  An optional default value and it's type can be provided if desired.

  ## Example

      iex> {test_var, expected_value} = System.get_env |> Enum.take(1) |> List.first
      ...> Application.put_env(:myapp, :test_var, {:system, test_var})
      ...> ^expected_value = #{__MODULE__}.get(:myapp, :test_var)
      ...> :ok
      :ok

      iex> Application.put_env(:myapp, :test_var2, 1)
      ...> 1 = #{__MODULE__}.get(:myapp, :test_var2)
      1

      iex> System.delete_env("TEST_ENV")
      ...> Application.put_env(:myapp, :test_var2, {:system, :integer, "TEST_ENV", "default_value"})
      ...> "default_value" = #{__MODULE__}.get(:myapp, :test_var2)
      ...> System.put_env("TEST_ENV", "123")
      ...> 123 = #{__MODULE__}.get(:myapp, :test_var2)
      123

      iex> :default = #{__MODULE__}.get(:myapp, :missing_var, :default)
      :default
  """
  @spec get(atom, atom, term | nil) :: term
  def get(app, key, default \\ nil) when is_atom(app) and is_atom(key) do
    app
    |> Application.get_env(key)
    |> get_value
    |> set_default(default)
  end

  @doc """
  Same as `get/3`, but when you has map.

  ## Example

    iex> {test_var, expected_value} = System.get_env |> Enum.take(1) |> List.first
    ...> Application.put_env(:myapp, :test_var, [test: {:system, test_var}])
    ...> [test: ^expected_value] = #{__MODULE__}.get_map(:myapp, :test_var)
    ...> :ok
    :ok

    iex> Application.put_env(:myapp, :test_var2, [test: 1])
    ...> #{__MODULE__}.get_map(:myapp, :test_var2)
    [test: 1]

    iex> :default = #{__MODULE__}.get_map(:myapp, :other_missing_var, :default)
    :default

    iex> Application.put_env(:myapp, :test_var3, [test: nil])
    ...> [test: nil] = #{__MODULE__}.get_map(:myapp, :test_var3)
    [test: nil]
  """
  @spec get_map(atom, atom, term | nil) :: Keyword.t
  def get_map(app, key, default \\ nil) when is_atom(app) and is_atom(key) do
    app
    |> Application.get_env(key)
    |> prepare_map
    |> set_default(default)
  end

  # Helpers to work with map values
  defp prepare_map(map, converter \\ &get_value/1)
  defp prepare_map(nil, _converter), do: nil
  defp prepare_map(map, converter) do
    map
    |> Enum.map(fn {key, value} ->
      case is_list(value) do
        true  ->
          {key, prepare_map(value, converter)}

        false ->
          {key, converter.(value)}
      end
    end)
  end

  # Helpers to parse value from supported definition tuples
  defp get_value({:system, type, var_name, default_value}) when is_atom(type) do
    var_name
    |> System.get_env
    |> cast(type)
    |> set_default(default_value)
  end

  defp get_value({:system, :string,  var_name}),
   do: get_value({:system, :string,  var_name, nil})

  defp get_value({:system, :integer, var_name}),
   do: get_value({:system, :integer, var_name, nil})

  defp get_value({:system, var_name, default_value}),
   do: get_value({:system, :string, var_name, default_value})

  defp get_value({:system, var_name}),
   do: get_value({:system, :string, var_name, nil})

  defp get_value(val),
   do: val

  # Helpers to cast value to correct type
  defp cast(nil, _), do: nil

  defp cast(value, :integer) do
    {int, _} = Integer.parse(value)
    int
  end

  defp cast(value, :string) do
    to_string(value)
  end

  # Set default value from `get` and `get_map` methods.
  # Basically we override all nil's with defaults.
  defp set_default(nil, default), do: default
  defp set_default(val, _), do: val

  # Helper to include configs into module and validate it at compile-time/run-time
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @otp_app Keyword.get(opts, :otp_app)

      def config do
        @otp_app
        |> Confex.get_map(__MODULE__)
        |> validate_config
      end

      defp validate_config(conf) do
        conf
      end

      defoverridable [validate_config: 1]
    end
  end
end
