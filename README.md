# Confex

[![Deps Status](https://beta.hexfaktor.org/badge/all/github/Nebo15/confex.svg)](https://beta.hexfaktor.org/github/Nebo15/confex) [![Inline docs](http://inch-ci.org/github/nebo15/confex.svg)](http://inch-ci.org/github/nebo15/confex) [![Hex.pm Downloads](https://img.shields.io/hexpm/dw/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![Latest Version](https://img.shields.io/hexpm/v/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![License](https://img.shields.io/hexpm/l/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![Build Status](https://travis-ci.org/Nebo15/confex.svg?branch=master)](https://travis-ci.org/Nebo15/confex) [![Coverage Status](https://coveralls.io/repos/github/Nebo15/confex/badge.svg?branch=master)](https://coveralls.io/github/Nebo15/confex?branch=master) [![Ebert](https://ebertapp.io/github/Nebo15/confex.svg)](https://ebertapp.io/github/Nebo15/confex)

Confex simplifies reading configuration at run-time with adapter-based system for fetch values from any source.
It's inspired by Phoenix `{:system, value}` definition for HTTP port and have no external dependencies.

## Installation

It's available on [hex.pm](https://hex.pm/packages/confex) and can be installed as project dependency:

  1. Add `confex` to your list of dependencies in `mix.exs`:

      ```elixir
      def deps do
        [{:confex, "~> 3.3.1"}]
      end
      ```

  2. Ensure `confex` is started before your application:

      ```elixir
      def application do
        [applications: [:confex]]
      end
      ```

# Usage

1. Replace values with configuration tuples

    Define configuration in your `config.exs`:

      ```elixir
      config :my_app, MyApp.MyQueue,
        queue: [
          name:        {:system, "OUT_QUEUE_NAME", "MyQueueOut"},
          error_name:  {:system, "OUT_ERROR_QUEUE_NAME", "MyQueueOut.Errors"},
          routing_key: {:system, "OUT_ROUTING_KEY", ""},
          durable:     {:system, "OUT_DURABLE", false},
          port:        {:system, :integer, "OUT_PORT", 1234},
        ]
      ```

    Configuration tuples examples:

    * `var` - any bare values will be left as-is.
    * `{:system, "ENV_NAME", "default"}` - read string from system environment or fallback to `"default"` if it is not set.
    * `{:system, "ENV_NAME"}` - same as above, but raise error if `ENV_NAME` is not set.

    Additionally you can cast string values to common types:

    * `{:system, :string, "ENV_NAME", "default"}` (string is a default type).
    * `{:system, :string, "ENV_NAME"}`.
    * `{:system, :integer, "ENV_NAME", 123}`.
    * `{:system, :integer, "ENV_NAME"}`.
    * `{:system, :float, "ENV_NAME", 123.5}`.
    * `{:system, :float, "ENV_NAME"}`.
    * `{:system, :boolean, "ENV_NAME", true}`.
    * `{:system, :boolean, "ENV_NAME"}`.
    * `{:system, :atom, "ENV_NAME"}`.
    * `{:system, :atom, "ENV_NAME", :default}`.
    * `{:system, :module, "ENV_NAME"}`.
    * `{:system, :module, "ENV_NAME", MyDefault}`.
    * `{:system, :list, "ENV_NAME"}`.
    * `{:system, :list, "ENV_NAME", [1, 2, 3]}`.

    `:system` can be replaced with a `{:via, adapter}` tuple, where adapter is a module that implements `Confex.Adapter` behaviour.

  Type can re replaced with `{module, function, arguments}` tuple, in this case Confex will use external function to
  resolve the type. Function must returns either `{:ok, value}` or `{:error, reason :: String.t}` tuple.

2. Read configuration by replacing `Application.fetch_env/2`, `Application.fetch_env!/2` and `Application.get_env/3` calls with `Confex` functions

    Fetch string values:

      ```elixir
      iex> Confex.fetch_env(:myapp, MyKey)
      {:ok, "abc"}
      ```

    Fetch integer values:

      ```elixir
      iex> Confex.fetch_env(:myapp, MyIntKey)
      {:ok, 123}
      ```

    Fetch configuration from maps or keywords:

      ```elixir
      iex> Confex.fetch_env(:myapp, MyIntKey)
      {:ok, [a: 123, b: "abc"]}
      ```

## Integrating with Ecto

`Ecto.Repo` has a [`init/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:init/2) callback, you can use it with Confex to read environment variables. We used to have all our repos to look like this:

```elixir
defmodule MyApp do
  use Ecto.Repo, otp_app: :my_app

  @doc """
  Dynamically loads the repository configuration from the environment variables.
  """
  def init(_, config) do
    url = System.get_env("DATABASE_URL")
    config = if url, do: [url: url] ++ config, else: Confex.Resolver.resolve!(config)

    unless config[:database] do
      raise "Set DB_NAME environment variable!"
    end

    {:ok, config}
  end
end
```

## Integrating with Phoenix

Same for Phoenix, use [`init/2`](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#c:init/2) callback of `Phoenix.Endpoint`:

```elixir
defmodule MyApp.Web.Endpoint do

  # Some code here

  @doc """
  Dynamically loads configuration from the system environment
  on startup.

  It receives the endpoint configuration from the config files
  and must return the updated configuration.
  """
  def init(_type, config) do
    {:ok, config} = Confex.Resolver.resolve(config)

    unless config[:secret_key_base] do
      raise "Set SECRET_KEY environment variable!"
    end

    {:ok, config}
  end
end
```

## Populating configuration at start-time

In case you want to keep using `Application.get_env/2` and other methods to keep accessing configuration,
you can resolve it one-time when application is started:

  ```elixir
  defmodule MyApp do
    use Application

    def start(_type, _args) do
      # Replace Application environment with resolved values
      Confex.resolve_env!(:my_app)

      # ...
    end
  end
  ```

However, don't drink too much Kool-Aid. Direct calls to the Confex are more explicit and should be default way to go,
you don't want your colleagues to waste their time finding out how that resolved value got into the configuration,
right?

## Using Confex macros

Confex is supplied with helper macros that allow to attach configuration to specific modules of your application.

  ```elixir
  defmodule Connection do
    use Confex, otp_app: :myapp
  end
  ```

  It will add `config/0` function to `Connection` module that reads configuration at run-time for `:myapp` OTP application with key `Connection`.

You can add defaults by extending macro options:

  ```elixir
  defmodule Connection do
    use Confex,
      otp_app: :myapp,
      some_value: {:system, "ENV_NAME", "this_will_be_default value"}
  end
  ```

  If application environment contains values in `Keyword` or `Map` structs, default values will be recursively merged with application configuration.

  We recommend to avoid using tuples without default values in this case, since `config/0` calls will raise exceptions if they are not resolved.

You can validate configuration by overriding `validate_config!/1` function, which will receive configuration and must return it back to caller function. It will be evaluated each time `config/1` is called.

  ```elixir
  defmodule Connection do
    use Confex, otp_app: :myapp

    def validate_config!(config) do
      unless config[:password] do
        raise "Password is not set!"
      end

      config
    end
  end
  ```

# Adapters

Currently Confex supports two embedded adapters:

  * `:system` - read configuration from system environment;
  * `:system_file` - read file path from system environment and read configuration from this file. Useful when you want to resolve Docker, Swarm or Kubernetes secrets that are stored in files.

You can create adapter by implementing `Confex.Adapter` behaviour with your own logic.

# Helpful links

* [Docs](https://hexdocs.pm/confex)
* [Runtime configuration, migrations and deployment for Elixir applications](https://medium.com/nebo-15/runtime-configuration-migrations-and-deployment-for-elixir-applications-6295b892fa6a).
* [REPLACE_OS_VARS in Distillery](https://hexdocs.pm/distillery/runtime-configuration.html#vm-args)
* [How to config environment variables with Elixir and Exrm](http://blog.plataformatec.com.br/2016/05/how-to-config-environment-variables-with-elixir-and-exrm/) by Platformatech.
