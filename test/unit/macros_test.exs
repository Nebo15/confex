defmodule ConfexMacrosTest do
  use ExUnit.Case
  doctest Confex

  defmodule TestModule do
    use Confex,
      otp_app: :confex,
      overriden_var: {:system, "OVER_VAR"},
      overriden_list: [list: [foo: "bar", mix: {:system, "OVER_VAR"}]]

    defp validate_config(config) do
      if is_nil(config) do
        throw "Something went wrong"
      end

      config
    end
  end

  defmodule TestModuleWithoutOTP do
    use Confex,
      overriden_var: {:system, "OVER_VAR"}

    defp validate_config(config) do
      if is_nil(config) do
        throw "Something went wrong #1"
      end

      config
    end
  end

  defmodule OtherModuleWithMacro do
    defmacro __using__(opts) do
      quote bind_quoted: [opts: opts] do
        use Confex, opts

        defp validate_config(config) do
          if is_nil(config) do
            throw "Something went wrong #2"
          end

          config
        end

        defoverridable [validate_config: 1]
      end
    end
  end

  defmodule OtherModuleWithMacro2 do
    defmacro __using__(opts) do
      quote bind_quoted: [opts: opts] do
        use OtherModuleWithMacro, opts

        defp validate_config(config) do
          if is_nil(config) do
            throw "Something went wrong #3"
          end

          config
        end
      end
    end
  end

  defmodule TestModuleFromMacro do
    use OtherModuleWithMacro2,
      some_var: "val"
  end

  setup do
    System.delete_env("TESTENV")
    System.delete_env("TESTINTENV")
    System.delete_env("OVER_VAR")

    Application.put_env(:confex, ConfexMacrosTest.TestModule, [
      foo: "bar",
      overriden_list: [list: [foo: "baz", bar: "foo"], key: "value"],
      num: 1,
      nix: {:system, :integer, "TESTINTENV"},
      tix: {:system, :integer, "TESTINTENV", 300},
      baz: {:system, "TESTENV"},
      biz: {:system, "TESTENV", "default_val"},
      mex: {:system, :string, "TESTENV"},
      tox: {:system, :string, "TESTENV", "default_val"},
    ])

    :ok
  end

  test "different definition types" do
    assert [overriden_var: nil,
            foo: "bar",
            overriden_list: [list: [mix: nil, foo: "baz", bar: "foo"], key: "value"],
            num: 1,
            nix: nil,
            tix: 300,
            baz: nil,
            biz: "default_val",
            mex: nil,
            tox: "default_val"] = TestModule.config

    System.put_env("TESTENV", "other_val")
    System.put_env("TESTINTENV", "600")
    System.put_env("OVER_VAR", "readme")

    assert [overriden_var: "readme",
            foo: "bar",
            overriden_list: [list: [mix: "readme", foo: "baz", bar: "foo"], key: "value"],
            num: 1,
            nix: 600,
            tix: 600,
            baz: "other_val",
            biz: "other_val",
            mex: "other_val",
            tox: "other_val"] = TestModule.config
  end

  test "module without OTP app" do
    assert [overriden_var: nil] = TestModuleWithoutOTP.config

    System.put_env("OVER_VAR", "readme")

    assert [overriden_var: "readme"] = TestModuleWithoutOTP.config
  end

  test "intermediate macro test" do
    assert [some_var: "val"] = TestModuleFromMacro.config

    System.put_env("TESTENV", "other_val")
    System.put_env("TESTINTENV", "600")
    System.put_env("OVER_VAR", "readme")

    assert [some_var: "val"] = TestModuleFromMacro.config
  end
end
