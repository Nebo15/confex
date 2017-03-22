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
    |> prepare_list
    |> set_default(default)
  end

  @doc """
  Receives Keyword list with Confex tuples and replaces them with an environment values.
  Useful when you want to store configs not in `config.exs`.

  # Example

      iex> [test: "defaults"] = #{__MODULE__}.process_env([test: {:system, "some_test_var", "defaults"}])
      [test: "defaults"]
  """
  @spec process_env(Keyword.t | atom | String.t | Integer.t) :: term
  def process_env(conf) when is_list(conf) do
    prepare_list(conf)
  end

  def process_env(conf) do
    get_value(conf)
  end

  # Helpers to work with map values
  defp prepare_list(map, converter \\ &get_value/1)
  defp prepare_list(nil, _converter), do: nil
  defp prepare_list(map, converter) do
    map
    |> Enum.map(&prepare_list_element(&1, converter))
  end

  defp prepare_list_element({key, value}, converter) when is_list(value) and key != :system do
    {key, prepare_list(value, converter)}
  end

  defp prepare_list_element({key, value}, converter) when key != :system do
    {key, converter.(value)}
  end

  defp prepare_list_element(value, _converter) do
    get_value(value)
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

  defp get_value({:system, :boolean, var_name}),
   do: get_value({:system, :boolean, var_name, nil})

  defp get_value({:system, :atom, var_name}),
   do: get_value({:system, :atom, var_name, nil})

  defp get_value({:system, :module, var_name}),
   do: get_value({:system, :module, var_name, nil})

  defp get_value({:system, :list, var_name}),
   do: get_value({:system, :list, var_name, nil})

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

  defp cast(value, :atom) do
    value
    |> String.to_char_list
    |> List.to_atom
  end

  defp cast(value, :module) do
    Module.concat([value])
  end

  defp cast(value, :string) do
    to_string(value)
  end

  @boolean_true ["true", "1", "yes"]
  @boolean_false ["false", "0", "no"]

  defp cast(value, :boolean) when is_binary(value) do
    dc_val = value
    |> String.downcase

    cond do
      Enum.member?(@boolean_true, dc_val)  ->
        true

      Enum.member?(@boolean_false, dc_val) ->
        false

      # Nil for all other values
      true ->
        nil
    end
  end

  @list_separator ","

  defp cast(value, :list) when is_binary(value) do
    value
    |> String.split(@list_separator)
    |> Enum.map(&String.trim/1)
  end


  # Set default value from `get` and `get_map` methods.
  # Basically we override all nil's with defaults.
  defp set_default(nil, default), do: default
  defp set_default(val, _), do: val

  # Helper to include configs into module and validate it at compile-time/run-time
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @dialyzer {:nowarn_function, add_defaults: 2}

      @otp_app opts
      |> Keyword.get(:otp_app)

      @module_config_overrides opts
      |> Keyword.delete(:otp_app)

      def config do
        @otp_app
        |> Confex.get_map(__MODULE__)
        |> add_defaults(@module_config_overrides)
        |> validate_config
      end

      defp add_defaults(conf, nil) do
        conf
        |> Confex.process_env
      end

      defp add_defaults(nil, defaults) do
        defaults
        |> Confex.process_env
      end

      defp add_defaults(conf, defaults) do
        defaults
        |> Keyword.merge(conf, &merge_recursive/3)
        |> Confex.process_env
      end

      defp merge_recursive(_k, v1, v2) do
        case is_list(v2) do
          true ->
            Keyword.merge(v1, v2, &merge_recursive/3)
          false ->
            v2
        end
      end

      def validate_config(conf) do
        conf
      end

      defoverridable [validate_config: 1]
    end
  end
end
