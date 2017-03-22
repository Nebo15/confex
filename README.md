# Confex

[![Deps Status](https://beta.hexfaktor.org/badge/all/github/Nebo15/confex.svg)](https://beta.hexfaktor.org/github/Nebo15/confex) [![Hex.pm Downloads](https://img.shields.io/hexpm/dw/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![Latest Version](https://img.shields.io/hexpm/v/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![License](https://img.shields.io/hexpm/l/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![Build Status](https://travis-ci.org/Nebo15/confex.svg?branch=master)](https://travis-ci.org/Nebo15/confex) [![Coverage Status](https://coveralls.io/repos/github/Nebo15/confex/badge.svg?branch=master)](https://coveralls.io/github/Nebo15/confex?branch=master) [![Ebert](https://ebertapp.io/github/Nebo15/confex.svg)](https://ebertapp.io/github/Nebo15/confex)

This is helper module that provides a nice way to read environment configuration at runtime. It's inspired by Phoenix `{:system, value}` definition for HTTP port.

## Installation

It's available on [hex.pm](https://hex.pm/packages/confex) and can be installed as project dependency:

  1. Add `confex` to your list of dependencies in `mix.exs`:

    def deps do
      [{:confex, "~> 1.5.0"}]
    end

  2. Ensure `confex` is started before your application:

    def application do
      [applications: [:confex]]
    end

# Usage

1. Defining configurations

  Define your configuration in config.ex of your application.

    config :ap_cfpredictor, AssetProcessor.AMQP.Producer,
      queue: [
        name:        {:system, "OUT_QUEUE_NAME", "MyQueueOut"},
        error_name:  {:system, "OUT_ERROR_QUEUE_NAME", "MyQueueOut.Errors"},
        routing_key: {:system, "OUT_ROUTING_KEY", ""},
        durable:     {:system, "OUT_DURABLE", false},
        port:        {:system, :integer, "OUT_PORT", 1234},
      ],

  List of supported formats:

  * `var` - any bare values will be left as-is.
  * `{:system, "ENV_NAME", default}` - read string from system ENV, return `default` if it's nil.
  * `{:system, "ENV_NAME"}` - read string from system ENV, returns `nil` if environment variables doesn't exist.
  * `{:system, :string, "ENV_NAME", default}` - same as `{:system, "ENV_NAME", default}`.
  * `{:system, :string, "ENV_NAME"}` - same as `{:system, "ENV_NAME"}`.
  * `{:system, :integer, "ENV_NAME", default}` - same as `{:system, "ENV_NAME", default}`, but will convert value to integer if it's not `nil`. Default value type **will not** be changed.
  * `{:system, :integer, "ENV_NAME"}` - same as `{:system, :integer, "ENV_NAME", nil}`.
  * `{:system, :boolean, "ENV_NAME", default}` - same as `{:system, "ENV_NAME", default}`, but will convert value to boolean if it's not `nil`. Default value type **will not** be changed.
  * `{:system, :boolean, "ENV_NAME"}` - same as `{:system, :boolean, "ENV_NAME", nil}`.
  * `{:system, :atom, "ENV_NAME"}`
  * `{:system, :atom, "ENV_NAME", :default}`
  * `{:system, :module, "ENV_NAME"}`
  * `{:system, :module, "ENV_NAME", Default}`
  * `{:system, :list, "ENV_NAME"}` - same as `{:system, :list, "ENV_NAME", nil}`.
  * `{:system, :list, "ENV_NAME", Default}` - same as `{:system, "ENV_NAME", default}`, but will convert value to list if it's not `nil`, splitting at commas. Default value type **will not** be changed.

2. Reading configuration

  Read string values:

    iex> Confex.get(:myapp, MyKey)
    "abc"

  Read integer values:

    Confex.get(:myapp, MyIntKey)
    123

  Read map values:

    Confex.get(:myapp, MyIntKey)
    [a: 123, b: "abc"]

3. Using macros

  Confex is supplied with helper macros that allow to attach configuration to specific modules of your application.

    defmodule Connection do
      use Confex, otp_app: :myapp
    end

  `Connection` in this case will read configuration from app `:myapp` with key `Connection`. Also it will provide helper function `config/0` that will return values at run-time.

4. Configuration validation

  Sometimes you want to validate configuration, for this you can define `def validate_config(config)` method, that will be called on each `config/0` usage.

  Confex doesn't give opinions on a validator to be used in overrided methods.

# Configuration priorities

By using Confex macro in your module, you allow to provide compile-time defaults for it.

  1. Declare module

    defmodule MyModule do
      use Confex
    end

  2. Provide defaults when using it

    use MyModule,
      otp_all: :myapp,
      host: {:system, "HOST"}

  This configs will overwritten by any configuration that you have in your application env.

# Helpful links

* [Docs](https://hexdocs.pm/confex)
