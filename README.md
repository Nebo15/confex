# Confex

[![Deps Status](https://beta.hexfaktor.org/badge/all/github/Nebo15/confex.svg)](https://beta.hexfaktor.org/github/Nebo15/confex) [![Hex.pm Downloads](https://img.shields.io/hexpm/dw/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![Latest Version](https://img.shields.io/hexpm/v/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![License](https://img.shields.io/hexpm/l/confex.svg?maxAge=3600)](https://hex.pm/packages/confex) [![Build Status](https://travis-ci.org/Nebo15/confex.svg?branch=master)](https://travis-ci.org/Nebo15/confex) [![Coverage Status](https://coveralls.io/repos/github/Nebo15/confex/badge.svg?branch=master)](https://coveralls.io/github/Nebo15/confex?branch=master)

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `confex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:confex, "~> 0.1.0"}]
    end
    ```

  2. Ensure `confex` is started before your application:

    ```elixir
    def application do
      [applications: [:confex]]
    end
    ```

If [published on HexDocs](https://hex.pm/docs/tasks#hex_docs), the docs can
be found at [https://hexdocs.pm/confex](https://hexdocs.pm/confex)

# Usage

1. Defining configurations

{:system, "ENV_NAME", default}
{:system, "ENV_NAME"}

{:system, :integer, "ENV_NAME", default}
{:system, :integer, "ENV_NAME"}

{:system, :string, "ENV_NAME", default}
{:system, :string, "ENV_NAME"}


2. Reading configuration

3. Using macros

4. Configuration validation

# Loading order

overrides -> env_var -> config.ex
