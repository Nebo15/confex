defmodule ConfexMacrosTest do
  use ExUnit.Case

  defmodule TestModule do
    use Confex,
      otp_app: :confex,
      overriden_var: {:system, "TESTENV_REQ"},
      overriden_keyword: [list: [foo: "foo", mix: {:system, "TESTENV", "default mix"}]],
      overriden_map: %{list: %{foo: "foo", mix: {:system, "TESTENV", "default mix"}}}

    def validate_config!(config) do
      if is_nil(config) do
        throw("Something went wrong")
      end

      config
    end
  end

  defmodule TestModuleWithoutDefaults do
    use Confex, otp_app: :confex
  end

  defmodule TestModuleWithMarco do
    defmacro __using__(opts) do
      quote bind_quoted: [opts: opts] do
        use Confex, opts

        def validate_config!(config) do
          if is_nil(config) do
            throw("Something went wrong #2")
          end

          config
        end

        defoverridable validate_config!: 1
      end
    end
  end

  defmodule TestModuleFromMacro do
    use TestModuleWithMarco,
      otp_app: :confex,
      my_default: {:system, "TESTENV", "default value"}
  end

  setup do
    System.delete_env("TESTENV")
    System.delete_env("TESTENV_INT")
    System.delete_env("TESTENV_REQ")

    Application.put_env(
      :confex,
      ConfexMacrosTest.TestModule,
      bare: "value",
      overriden_keyword: [list: [foo: "baz", bar: "bar"], key: "value"],
      overriden_map: %{list: %{foo: "baz", bar: "bar"}, key: "value"},
      integer: 1,
      integer_tuple: {:system, :integer, "TESTENV_INT"},
      integer_tuple_with_default: {:system, :integer, "TESTENV_INT", 300},
      string_tuple: {:system, "TESTENV"},
      string_tuple_with_default: {:system, "TESTENV", "default biz"}
    )

    :ok
  end

  test "uses defaults when app config can not be resolved" do
    message = "can not resolve key TESTENV_REQ value via adapter Elixir.Confex.Adapters.SystemEnvironment"

    assert_raise ArgumentError, message, fn ->
      TestModule.config()
    end

    System.put_env("TESTENV_REQ", "custom req value")

    config = [
      overriden_var: "custom req value",
      overriden_keyword: [list: [foo: "foo", mix: "default mix"]],
      overriden_map: %{list: %{foo: "foo", mix: "default mix"}}
    ]

    assert TestModule.config() == config
  end

  test "resolves configuration without defaults" do
    System.put_env("TESTENV", "custom value")
    Application.put_env(:confex, ConfexMacrosTest.TestModuleWithoutDefaults, string_tuple: {:system, "TESTENV"})

    assert TestModuleWithoutDefaults.config() == [string_tuple: "custom value"]
  end

  test "merges and resolves configuration" do
    System.put_env("TESTENV", "custom value")
    System.put_env("TESTENV_INT", "600")
    System.put_env("TESTENV_REQ", "custom req value")

    config = [
      overriden_var: "custom req value",
      bare: "value",
      overriden_keyword: [
        key: "value",
        list: [mix: "custom value", foo: "baz", bar: "bar"]
      ],
      overriden_map: %{key: "value", list: %{mix: "custom value", foo: "baz", bar: "bar"}},
      integer: 1,
      integer_tuple: 600,
      integer_tuple_with_default: 600,
      string_tuple: "custom value",
      string_tuple_with_default: "custom value"
    ]

    assert TestModule.config() == config
  end

  test "can be used in intermediate marco" do
    assert TestModuleFromMacro.config() == [my_default: "default value"]
    System.put_env("TESTENV", "custom value")
    assert TestModuleFromMacro.config() == [my_default: "custom value"]
  end
end
