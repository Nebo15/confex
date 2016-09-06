# Confex

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
