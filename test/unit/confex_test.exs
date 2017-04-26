defmodule ConfexTest do
  use ExUnit.Case
  doctest Confex

  setup do
    System.delete_env("TESTENV")
    Application.delete_env(:confex, __MODULE__)
    :ok
  end

  test "use nil maps" do
    assert nil == Confex.get_map(:myapp, :missing_map)
  end

  test "keeps bare values" do
    Application.put_env(:confex, __MODULE__, [
       string: "bar",
       integer: 1,
       list: [1, 2, 3],
       tuple: {1, 2, 3, {:system, "THIS_DOESNT_WORK"}},
       map: %{key: {:system, "THIS_DOESNT_WORK"}}
    ])

    assert [string: "bar",
            integer: 1,
            list: [1, 2, 3],
            tuple: {1, 2, 3, {:system, "THIS_DOESNT_WORK"}},
            map: %{key: {:system, "THIS_DOESNT_WORK"}}] = Confex.get_map(:confex, __MODULE__)
  end

  test "sets integers" do
    Application.put_env(:confex, __MODULE__, [
       a: {:system, :integer, "TESTENV"},
       b: {:system, :integer, "TESTENV", 300},
    ])

    assert [a: nil,
            b: 300] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "600")

    assert [a: 600,
            b: 600] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "abba")

    assert_raise ArgumentError, ~S/Environment variable "TESTENV" can not be parsed as integer. / <>
                                ~S/Got value: "abba"/, fn ->
      Confex.get_map(:confex, __MODULE__)
    end
  end

  test "sets booleans" do
    Application.put_env(:confex, __MODULE__, [
       a: {:system, :boolean, "TESTENV"},
       b: {:system, :boolean, "TESTENV", true},
    ])

    assert [a: nil,
            b: true] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "true")

    assert [a: true,
            b: true] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "false")

    assert [a: false,
            b: false] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "TRuE")

    assert [a: true,
            b: true] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "FaLSE")

    assert [a: false,
            b: false] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "1")

    assert [a: true,
            b: true] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "0")

    assert [a: false,
            b: false] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "yes")

    assert [a: true,
            b: true] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "No")

    assert [a: false,
            b: false] = Confex.get_map(:confex, __MODULE__)


    System.put_env("TESTENV", "hola")

    assert_raise ArgumentError, ~S/Environment variable "TESTENV" can not be parsed as boolean. / <>
                                ~S/Expected 'true', 'false', '1', '0', 'yes' or 'no', got: "hola"/, fn ->
      Confex.get_map(:confex, __MODULE__)
    end

    System.put_env("TESTENV", "como_estas?")

    assert_raise ArgumentError, fn ->
      assert [a: nil,
              b: true] = Confex.get_map(:confex, __MODULE__)
    end
  end

  test "sets strings" do
    Application.put_env(:confex, __MODULE__, [
       a: {:system, :string, "TESTENV"},
       b: {:system, :string, "TESTENV", "default_val"},
       c: {:system, "TESTENV"},
       d: {:system, "TESTENV", "default_val"}
    ])

    assert [a: nil,
            b: "default_val",
            c: nil,
            d: "default_val"] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "env_val")

    assert [a: "env_val",
            b: "env_val",
            c: "env_val",
            d: "env_val"] = Confex.get_map(:confex, __MODULE__)
  end

  test "sets atoms" do
    System.put_env("TESTENV", "my_symbol")

    Application.put_env(:confex, __MODULE__, [
       a: {:system, :atom, "TESTENV"},
    ])

    assert [a: :my_symbol] = Confex.get_map(:confex, __MODULE__)
  end

  test "sets modules" do
    System.put_env("TESTENV", "MyModule")

    Application.put_env(:confex, __MODULE__, [
       a: {:system, :module, "TESTENV"},
    ])

    assert [a: MyModule] = Confex.get_map(:confex, __MODULE__)
  end

  test "sets lists" do
    System.put_env("TESTENV", "foo, bar, baz")

    Application.put_env(:confex, __MODULE__, [
       a: {:system, :list, "TESTENV"}
    ])

    assert [a: ["foo", "bar", "baz"]] = Confex.get_map(:confex, __MODULE__)
  end

  test "walks on nested maps" do
    Application.put_env(:confex, __MODULE__, [
       a: [aa: "bar",
           ab: 1],
       b: {:system, :integer, "TESTENV"},
       c: [ca: {:system, :integer, "TESTENV", 300}],
       d: [1, 2, {:system, :integer, "TESTENV", 300}]
    ])

    assert [a: [aa: "bar",
                ab: 1],
            b: nil,
            c: [ca: 300],
            d: [1, 2, 300]] = Confex.get_map(:confex, __MODULE__)

    System.put_env("TESTENV", "600")

    assert [a: [aa: "bar",
                ab: 1],
            b: 600,
            c: [ca: 600],
            d: [1, 2, 600]] = Confex.get_map(:confex, __MODULE__)
  end

  test "processes environment maps" do
    System.delete_env("process_test_var")
    assert [test: "defaults"] = Confex.process_env([test: {:system, "process_test_var", "defaults"}])
    System.put_env("process_test_var", "other_val")
    assert [test: "other_val"] = Confex.process_env([test: {:system, "process_test_var", "defaults"}])
    assert "bare_value" = Confex.process_env("bare_value")
  end
end
