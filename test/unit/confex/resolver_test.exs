defmodule Confex.ResolverTest do
  use ExUnit.Case, async: false
  alias Confex.Resolver
  doctest Confex.Resolver

  describe "resolve/1" do
    test "resolves nil values" do
      assert {:ok, nil} == Resolver.resolve(nil)
    end

    test "resolves values in maps" do
      assert {:ok, %{key: "default_value"}} == Resolver.resolve(%{key: {:system, "DOES_NOT_EXIST", "default_value"}})
    end

    test "resolves values in nested maps" do
      assert {:ok, %{parent: %{child: "default_value"}}}
        == Resolver.resolve(%{parent: %{child: {:system, "DOES_NOT_EXIST", "default_value"}}})
    end

    test "resolves values in keywords" do
      assert {:ok, [key: "default_value"]} == Resolver.resolve([key: {:system, "DOES_NOT_EXIST", "default_value"}])
    end

    test "resolves values in nested keywords" do
      assert {:ok, [parent: [child: "default_value"]]}
        == Resolver.resolve([parent: [child: {:system, "DOES_NOT_EXIST", "default_value"}]])
    end

    test "does not resolve in tuples" do
      assert {:ok, {1, 2, 3, {:system, "KEEP_THIS"}}} == Resolver.resolve({1, 2, 3, {:system, "KEEP_THIS"}})
    end

    test "does not resolve in lists" do
      assert {:ok, [1, 2, 3, {:system, "KEEP_THIS"}]} == Resolver.resolve([1, 2, 3, {:system, "KEEP_THIS"}])
    end

    test "does not break complex structures" do
      config = [
        string: "bar",
        integer: 1,
        list: [1, 2, 3],
        tuple: {1, 2, 3},
        map: %{key: [child: :value]}
      ]

      assert {:ok, config} == Resolver.resolve(config)
    end
  end

  describe "resolve!/1" do
    test "resolves values" do
      assert nil == Resolver.resolve!(nil)
    end

    test "raises when variable does not exist" do
      assert_raise ArgumentError, fn ->
        Resolver.resolve!(%{key: {:system, "DOES_NOT_EXIST"}})
      end
    end

    test "raises when variable can not be casted not exist" do
      System.put_env("TESTENV", "abc")

      on_exit(fn ->
        System.delete_env("TESTENV")
      end)

      assert_raise ArgumentError, fn ->
        Resolver.resolve!(%{key: {:system, :integer, "TESTENV"}})
      end
    end
  end

  describe "supports all configuration styles" do
    setup do
      System.delete_env("TESTENV")
      on_exit(fn ->
        System.delete_env("TESTENV")
      end)
    end

    test "for strings" do
      System.put_env("TESTENV", "foo")
      assert {:ok, "foo"} == Resolver.resolve({:system, "TESTENV"})
      assert {:ok, "foo"} == Resolver.resolve({:system, :string, "TESTENV"})
      assert {:ok, "foo"} == Resolver.resolve({:system, "DOES_NOT_EXIST", "foo"})
      assert {:ok, "foo"} == Resolver.resolve({:system, :string, "DOES_NOT_EXIST", "foo"})
    end

    test "for integers" do
      System.put_env("TESTENV", "123")
      assert {:ok, 123} == Resolver.resolve({:system, :integer, "TESTENV"})
      assert {:ok, 123} == Resolver.resolve({:system, :integer, "DOES_NOT_EXIST", 123})

      System.put_env("TESTENV", "abc")
      assert {:error, {:invalid, ~s/can not cast "abc" to Integer/}}
        == Resolver.resolve({:system, :integer, "TESTENV", 123})

      assert {:error, {:unresolved, "can not resolve key DOES_NOT_EXIST value " <>
                                    "via adapter Elixir.Confex.Adapters.SystemEnvironment"}}
        == Resolver.resolve({:system, :integer, "DOES_NOT_EXIST"})
    end

    test "for floats" do
      System.put_env("TESTENV", "123.5")
      assert {:ok, 123.5} == Resolver.resolve({:system, :float, "TESTENV"})
      assert {:ok, 123.5} == Resolver.resolve({:system, :float, "DOES_NOT_EXIST", 123.5})

      System.put_env("TESTENV", "abc")
      assert {:error, {:invalid, ~s/can not cast "abc" to Float/}}
        == Resolver.resolve({:system, :float, "TESTENV", 123.5})

      assert {:error, {:unresolved, "can not resolve key DOES_NOT_EXIST value " <>
                                    "via adapter Elixir.Confex.Adapters.SystemEnvironment"}}
        == Resolver.resolve({:system, :float, "DOES_NOT_EXIST"})
    end

    test "for atoms" do
      System.put_env("TESTENV", "abc")
      assert {:ok, :abc} == Resolver.resolve({:system, :atom, "TESTENV"})
      assert {:ok, :abc} == Resolver.resolve({:system, :atom, "DOES_NOT_EXIST", :abc})

      assert {:error, {:unresolved, "can not resolve key DOES_NOT_EXIST value " <>
                                    "via adapter Elixir.Confex.Adapters.SystemEnvironment"}}
        == Resolver.resolve({:system, :atom, "DOES_NOT_EXIST"})
    end

    test "for modules" do
      System.put_env("TESTENV", "MyModule")
      assert {:ok, MyModule} == Resolver.resolve({:system, :module, "TESTENV"})
      assert {:ok, MyModule} == Resolver.resolve({:system, :module, "DOES_NOT_EXIST", MyModule})

      assert {:error, {:unresolved, "can not resolve key DOES_NOT_EXIST value " <>
                                    "via adapter Elixir.Confex.Adapters.SystemEnvironment"}}
        == Resolver.resolve({:system, :module, "DOES_NOT_EXIST"})
    end

    test "for booleans" do
      System.put_env("TESTENV", "true")
      assert {:ok, true} == Resolver.resolve({:system, :boolean, "TESTENV"})
      assert {:ok, true} == Resolver.resolve({:system, :boolean, "DOES_NOT_EXIST", true})

      System.put_env("TESTENV", "abc")
      assert {:error, {:invalid, ~s/can not cast "abc" to boolean, / <>
                                 ~s/expected values are 'true', 'false', '1', '0', 'yes' or 'no'/}}
        == Resolver.resolve({:system, :boolean, "TESTENV", false})

      assert {:error, {:unresolved, "can not resolve key DOES_NOT_EXIST value " <>
                                    "via adapter Elixir.Confex.Adapters.SystemEnvironment"}}
        == Resolver.resolve({:system, :boolean, "DOES_NOT_EXIST"})
    end

    test "for lists" do
      System.put_env("TESTENV", "1,2,3")
      assert {:ok, ["1", "2", "3"]} == Resolver.resolve({:system, :list, "TESTENV"})
      assert {:ok, ["1", "2", "3"]} == Resolver.resolve({:system, :list, "DOES_NOT_EXIST", ["1", "2", "3"]})

      assert {:error, {:unresolved, "can not resolve key DOES_NOT_EXIST value " <>
                                    "via adapter Elixir.Confex.Adapters.SystemEnvironment"}}
        == Resolver.resolve({:system, :list, "DOES_NOT_EXIST"})
    end
  end

  test "resolves with custom adapters" do
    assert {:ok, "foo"} == Resolver.resolve({Confex.Adapters.SystemEnvironment, "DOES_NOT_EXIST", "foo"})
  end
end
