defmodule Confex do
  @moduledoc """
  Confex simplifies reading configuration at run-time with adapter-based system for resolvers.

  # Configuration tuples

  Whenever there is a configuration that should be resolved at run-time you need to replace it's value in `config.exs`
  by Confex configuration type. Common structure:

    ```elixir
    @type fetch_statement :: {adapter :: atom() | module(), value_type :: value_type, key :: String.t, default :: any()}
                           | {value_type :: value_type, key :: String.t}
                           | {key :: String.t, default :: any()}
                           | {key :: String.t}
    ```

  If `value_type` is set, Confex will automatically cast it's value. Otherwise, default type of `:string` is used.

  | Confex Type | Elixir Type       | Description |
  | ----------- | ----------------- | ----------- |
  | `:string`   | `String.t`        | Default.    |
  | `:integer`  | `Integer.t`       | Parse Integer value in string. |
  | `:float`    | `Float.t`         | Parse Float value in string. |
  | `:boolean`  | `true` or `false` | Cast 'true', '1', 'yes' to `true`; 'false', '0', 'no' to `false`. |
  | `:atom`     | `atom()`          | Cast string to atom. |
  | `:module`   | `module()`        | Cast string to module name. |
  | `:list`     | `List.t`          | Cast comma-separated string (`1,2,3`) to list (`[1, 2, 3]`). |

  # Custom type casting

  You can use your own casting function by replacing type with `{module, function, arguments}` tuple,
  Confex will call that function with `apply(module, function, [value] ++ arguments)`.

  This function returns either `{:ok, value}` or `{:error, reason :: String.t}` tuple.

  # Adapters

    * `:system` - read configuration from system environment;
    * `:system_file` - read file path from system environment and read configuration from this file.

  You can create adapter by implementing `Confex.Adapter` behaviour with your own logic.

  # Examples

    * `var` - any bare values will be left as-is;
    * `{:system, "ENV_NAME", default}` - read string from "ENV_NAME" environment variable or return `default` \
    if it's not set or has empty value;
    * `{:system, "ENV_NAME"}` - same as above, with default value `nil`;
    * `{:system, :integer, "ENV_NAME", default}` - read string from "ENV_NAME" environment variable and cast it \
    to integer or return `default` if it's not set or has empty value;
    * `{:system, :integer, "ENV_NAME"}` - same as `{:system, :integer, "ENV_NAME", nil}`;
    * `{{:via, MyAdapter}, :string, "ENV_NAME", default}` - read value by key "ENV_NAME" via adapter `MyAdapter` \
    or return `default` if it's not set or has empty value;
    * `{{:via, MyAdapter}, :string, "ENV_NAME"}` - same as above, with default value `nil`;
    * `{:system, {MyApp.MyType, :cast, [:foo]}, "ENV_NAME"}` - `MyApp.MyType.cast(value, :foo)` call would be made \
    to resolve environment variable value.
  """
  alias Confex.Resolver

  @typep app :: Application.app()
  @typep key :: Application.key()
  @typep value :: Application.value()

  @type configuration_tuple ::
          {value_type :: Confex.Type.t(), key :: String.t(), default :: any()}
          | {value_type :: Confex.Type.t(), key :: String.t()}
          | {key :: String.t(), default :: any()}
          | {key :: String.t()}

  @doc """
  Returns the value for key in app’s environment in a tuple.
  This function mimics `Application.fetch_env/2` function.

  If the configuration parameter does not exist or can not be parsed, the function returns :error.

  ## Example

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, "MY_TEST_ENV"})
      ...> {:ok, "foo"} = #{__MODULE__}.fetch_env(:myapp, :test_var)
      {:ok, "foo"}

      iex> :ok = System.delete_env("MY_TEST_ENV")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV", "bar"})
      ...> {:ok, "bar"} = #{__MODULE__}.fetch_env(:myapp, :test_var)
      {:ok, "bar"}

      iex> :ok = System.delete_env("MY_TEST_ENV")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> :error = #{__MODULE__}.fetch_env(:myapp, :test_var)
      :error

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> :error = #{__MODULE__}.fetch_env(:myapp, :test_var)
      :error

      iex> Application.put_env(:myapp, :test_var, 1)
      ...> {:ok, 1} = #{__MODULE__}.fetch_env(:myapp, :test_var)
      {:ok, 1}
  """
  @spec fetch_env(app :: app(), key :: key()) :: {:ok, value()} | :error
  def fetch_env(app, key) do
    with {:ok, config} <- Application.fetch_env(app, key),
         {:ok, config} <- Resolver.resolve(config) do
      {:ok, config}
    else
      :error -> :error
      {:error, _reason} -> :error
    end
  end

  @doc """
  Returns the value for key in app’s environment.
  This function mimics `Application.fetch_env!/2` function.

  If the configuration parameter does not exist or can not be parsed, raises `ArgumentError`.

  ## Example

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, "MY_TEST_ENV"})
      ...> "foo" = #{__MODULE__}.fetch_env!(:myapp, :test_var)
      "foo"

      iex> :ok = System.delete_env("MY_TEST_ENV")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV", "bar"})
      ...> "bar" = #{__MODULE__}.fetch_env!(:myapp, :test_var)
      "bar"

      iex> :ok = System.delete_env("MY_TEST_ENV")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> #{__MODULE__}.fetch_env!(:myapp, :test_var)
      ** (ArgumentError) can't fetch value for key `:test_var` of application `:myapp`, \
  can not resolve key MY_TEST_ENV value via adapter Elixir.Confex.Adapters.SystemEnvironment

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> #{__MODULE__}.fetch_env!(:myapp, :test_var)
      ** (ArgumentError) can't fetch value for key `:test_var` of application `:myapp`, can not cast "foo" to Integer

      iex> Application.put_env(:myapp, :test_var, 1)
      ...> 1 = #{__MODULE__}.fetch_env!(:myapp, :test_var)
      1
  """
  @spec fetch_env!(app :: app(), key :: key()) :: value() | no_return
  def fetch_env!(app, key) do
    config = Application.fetch_env!(app, key)

    case Resolver.resolve(config) do
      {:ok, config} ->
        config

      {:error, {_reason, message}} ->
        raise ArgumentError, "can't fetch value for key `#{inspect(key)}` of application `#{inspect(app)}`, #{message}"
    end
  end

  @doc """
  Returns the value for key in app’s environment in a tuple.
  This function mimics `Application.get_env/2` function.

  If the configuration parameter does not exist or can not be parsed, returns default value or `nil`.

  ## Example

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, "MY_TEST_ENV"})
      ...> "foo" = #{__MODULE__}.get_env(:myapp, :test_var)
      "foo"

      iex> :ok = System.delete_env("MY_TEST_ENV")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV", "bar"})
      ...> "bar" = #{__MODULE__}.get_env(:myapp, :test_var)
      "bar"

      iex> :ok = System.delete_env("MY_TEST_ENV")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> nil = #{__MODULE__}.get_env(:myapp, :test_var)
      nil

      iex> :ok = System.delete_env("MY_TEST_ENV")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> "baz" = #{__MODULE__}.get_env(:myapp, :test_var, "baz")
      "baz"

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> nil = #{__MODULE__}.get_env(:myapp, :test_var)
      nil

      iex> nil = #{__MODULE__}.get_env(:myapp, :does_not_exist)
      nil

      iex> Application.put_env(:myapp, :test_var, 1)
      ...> 1 = #{__MODULE__}.get_env(:myapp, :test_var)
      1
  """
  @spec get_env(app :: app(), key :: key(), default :: value()) :: value()
  def get_env(app, key, default \\ nil) do
    with {:ok, config} <- Application.fetch_env(app, key),
         {:ok, config} <- Resolver.resolve(config) do
      config
    else
      :error -> default
      {:error, _reason} -> default
    end
  end

  @doc """
  Reads all key-value pairs from an application environment and replaces them
  with resolved values.

  # Example

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, "MY_TEST_ENV"})
      ...> Confex.resolve_env!(:myapp)
      ...> "foo" = Application.get_env(:myapp, :test_var)
      "foo"

      iex> :ok = System.put_env("MY_TEST_ENV", "foo")
      ...> Application.put_env(:myapp, :test_var, {:system, :integer, "MY_TEST_ENV"})
      ...> Confex.resolve_env!(:myapp)
      ** (ArgumentError) can't fetch value for key `:test_var` of application `:myapp`, can not cast "foo" to Integer

  *Warning!* Do not use this function if you want to change your environment
  while VM is running. All `{:system, _}` tuples would be replaced with actual values.
  """
  @spec resolve_env!(app :: app()) :: [{key(), value()}] | no_return
  def resolve_env!(app) do
    app
    |> Application.get_all_env()
    |> Enum.map(&resolve_and_update_env(app, &1))
  end

  defp resolve_and_update_env(app, {key, config}) do
    case Resolver.resolve(config) do
      {:ok, config} ->
        :ok = Application.put_env(app, key, config)
        {key, config}

      {:error, {_reason, message}} ->
        raise ArgumentError, "can't fetch value for key `#{inspect(key)}` of application `#{inspect(app)}`, " <> message
    end
  end

  @doc """
  Recursively merges configuration with default values.

  Both values must be either in `Keyword` or `Map` structures, otherwise ArgumentError is raised.

  ## Example

      iex> [b: 3, a: 1] = #{__MODULE__}.merge_configs!([a: 1], [a: 2, b: 3])
      [b: 3, a: 1]

      iex> %{a: 1, b: 3} = #{__MODULE__}.merge_configs!(%{a: 1}, %{a: 2, b: 3})
      %{a: 1, b: 3}

      iex> #{__MODULE__}.merge_configs!(%{a: 1}, [b: 2])
      ** (ArgumentError) can not merge default values [b: 2] with configuration %{a: 1} because their types mismatch, \
  expected both to be either Map or Keyword structures
  """
  @spec merge_configs!(config :: Keyword.t() | map, defaults :: Keyword.t() | map) :: Keyword.t() | map
  def merge_configs!(config, []), do: config
  def merge_configs!(nil, defaults), do: defaults

  def merge_configs!(config, defaults) do
    cond do
      Keyword.keyword?(config) and Keyword.keyword?(defaults) ->
        defaults
        |> Keyword.merge(config, &compare/3)
        |> Resolver.resolve!()

      is_map(config) and is_map(defaults) ->
        defaults
        |> Map.merge(config, &compare/3)
        |> Resolver.resolve!()

      true ->
        raise ArgumentError,
              "can not merge default values #{inspect(defaults)} " <>
                "with configuration #{inspect(config)} because their types mismatch, " <>
                "expected both to be either Map or Keyword structures"
    end
  end

  defp compare(_k, v1, v2) do
    if is_map(v2) or Keyword.keyword?(v2) do
      merge_configs!(v1, v2)
    else
      v2
    end
  end

  # Helper to include configuration into module and validate it at compile-time/run-time.
  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      @otp_app Keyword.fetch!(opts, :otp_app)
      @module_config_defaults Keyword.delete(opts, :otp_app)

      @doc """
      Returns module configuration.

      If application environment contains values in `Keyword` or `Map` struct,
      defaults from macro usage will be recursively merged with application configuration.

      If one of the configuration parameters does not exist or can not be resolved, raises `ArgumentError`.
      """
      @spec config() :: any()
      def config do
        @otp_app
        |> Confex.get_env(__MODULE__)
        |> Confex.merge_configs!(@module_config_defaults)
        |> Confex.Resolver.resolve!()
        |> validate_config!()
      end

      @spec validate_config!(config :: any()) :: any()
      def validate_config!(config), do: config

      defoverridable validate_config!: 1
    end
  end
end
