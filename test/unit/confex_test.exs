defmodule ConfexTest do
  use ExUnit.Case
  doctest Confex

  test "use nil maps" do
    assert nil == Confex.get_map(:myapp, :missing_map)
  end

  test "different definition types" do
    Application.put_env(:confex, __MODULE__, [
       foo: "bar",
       num: 1,
       baz: {:system, "TESTENV"},
       biz: {:system, "TESTENV", "default_val"},
       mex: {:system, :string, "TESTENV"},
       tox: {:system, :string, "TESTENV", "default_val"},
    ])

    assert [foo: "bar",
            num: 1,
            baz: nil,
            biz: "default_val",
            mex: nil,
            tox: "default_val"] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "other_val")

    assert [foo: "bar",
            num: 1,
            baz: "other_val",
            biz: "other_val",
            mex: "other_val",
            tox: "other_val"] = Confex.get_map(:confex, __MODULE__)
  end

  test "integer fields" do
    Application.put_env(:confex, __MODULE__, [
       foo: "bar",
       num: 1,
       mex: {:system, :integer, "TESTINTENV"},
       tox: {:system, :integer, "TESTINTENV", 300},
    ])

    assert [foo: "bar",
            num: 1,
            mex: nil,
            tox: 300] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTINTENV", "600")

    assert [foo: "bar",
            num: 1,
            mex: 600,
            tox: 600] = Confex.get_map(:confex, __MODULE__)
  end
end
