defmodule Confex.ResolverTest do
  use ExUnit.Case, async: false
  alias Confex.Resolver
  doctest Confex.Resolver

  defmodule TestAdapter do
    @behaviour Confex.Adapter

    def fetch_value(key), do: {:ok, key}
  end

  describe "resolve/1" do
    test "resolves nil values" do
      assert Resolver.resolve(nil) == {:ok, nil}
    end

    test "resolves values in maps" do
      assert Resolver.resolve(%{key: {:system, "DOES_NOT_EXIST", "default_value"}}) == {:ok, %{key: "default_value"}}
    end

    test "resolves values in nested maps" do
      config = %{parent: %{child: "default_value"}}
      assert Resolver.resolve(%{parent: %{child: {:system, "DOES_NOT_EXIST", "default_value"}}}) == {:ok, config}
    end

    test "resolves values in keywords" do
      assert Resolver.resolve(key: {:system, "DOES_NOT_EXIST", "default_value"}) == {:ok, [key: "default_value"]}
    end

    test "resolves values in nested keywords" do
      config = [parent: [child: "default_value"]]
      assert Resolver.resolve(parent: [child: {:system, "DOES_NOT_EXIST", "default_value"}]) == {:ok, config}
    end

    test "does not resolve in tuples" do
      assert Resolver.resolve({1, 2, 3, {:system, "KEEP_THIS"}}) == {:ok, {1, 2, 3, {:system, "KEEP_THIS"}}}
    end

    test "does not resolve in lists" do
      assert Resolver.resolve([1, 2, 3, {:system, "KEEP_THIS"}]) == {:ok, [1, 2, 3, {:system, "KEEP_THIS"}]}
    end

    test "does not break complex structures" do
      config = [
        string: "bar",
        integer: 1,
        list: [1, 2, 3],
        tuple: {1, 2, 3},
        map: %{key: [child: :value]}
      ]

      assert Resolver.resolve(config) == {:ok, config}
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
      assert Resolver.resolve({:system, "TESTENV"}) == {:ok, "foo"}
      assert Resolver.resolve({:system, :string, "TESTENV"}) == {:ok, "foo"}
      assert Resolver.resolve({:system, "DOES_NOT_EXIST", "foo"}) == {:ok, "foo"}
      assert Resolver.resolve({:system, :string, "DOES_NOT_EXIST", "foo"}) == {:ok, "foo"}
    end

    test "for integers" do
      System.put_env("TESTENV", "123")
      assert Resolver.resolve({:system, :integer, "TESTENV"}) == {:ok, 123}
      assert Resolver.resolve({:system, :integer, "DOES_NOT_EXIST", 123}) == {:ok, 123}

      System.put_env("TESTENV", "abc")

      reason = {:invalid, ~s/can not cast "abc" to Integer/}
      assert Resolver.resolve({:system, :integer, "TESTENV", 123}) == {:error, reason}

      reason = {
        :unresolved,
        "can not resolve key DOES_NOT_EXIST value via adapter Elixir.Confex.Adapters.SystemEnvironment"
      }

      assert Resolver.resolve({:system, :integer, "DOES_NOT_EXIST"}) == {:error, reason}
    end

    test "for floats" do
      System.put_env("TESTENV", "123.5")
      assert Resolver.resolve({:system, :float, "TESTENV"}) == {:ok, 123.5}
      assert Resolver.resolve({:system, :float, "DOES_NOT_EXIST", 123.5}) == {:ok, 123.5}

      System.put_env("TESTENV", "abc")

      reason = {:invalid, ~s/can not cast "abc" to Float/}
      assert Resolver.resolve({:system, :float, "TESTENV", 123.5}) == {:error, reason}

      reason = {
        :unresolved,
        "can not resolve key DOES_NOT_EXIST value via adapter Elixir.Confex.Adapters.SystemEnvironment"
      }

      assert Resolver.resolve({:system, :float, "DOES_NOT_EXIST"}) == {:error, reason}
    end

    test "for atoms" do
      System.put_env("TESTENV", "abc")
      assert {:ok, :abc} == Resolver.resolve({:system, :atom, "TESTENV"})
      assert {:ok, :abc} == Resolver.resolve({:system, :atom, "DOES_NOT_EXIST", :abc})

      reason = {
        :unresolved,
        "can not resolve key DOES_NOT_EXIST value via adapter Elixir.Confex.Adapters.SystemEnvironment"
      }

      assert Resolver.resolve({:system, :atom, "DOES_NOT_EXIST"}) == {:error, reason}
    end

    test "for modules" do
      System.put_env("TESTENV", "MyModule")
      assert {:ok, MyModule} == Resolver.resolve({:system, :module, "TESTENV"})
      assert {:ok, MyModule} == Resolver.resolve({:system, :module, "DOES_NOT_EXIST", MyModule})

      reason = {
        :unresolved,
        "can not resolve key DOES_NOT_EXIST value via adapter Elixir.Confex.Adapters.SystemEnvironment"
      }

      assert Resolver.resolve({:system, :module, "DOES_NOT_EXIST"}) == {:error, reason}
    end

    test "for booleans" do
      System.put_env("TESTENV", "true")
      assert {:ok, true} == Resolver.resolve({:system, :boolean, "TESTENV"})
      assert {:ok, true} == Resolver.resolve({:system, :boolean, "DOES_NOT_EXIST", true})

      System.put_env("TESTENV", "abc")

      reason = {
        :invalid,
        ~s/can not cast "abc" to boolean, expected values are 'true', 'false', '1', '0', 'yes' or 'no'/
      }

      assert Resolver.resolve({:system, :boolean, "TESTENV", false}) == {:error, reason}

      reason = {
        :unresolved,
        "can not resolve key DOES_NOT_EXIST value via adapter Elixir.Confex.Adapters.SystemEnvironment"
      }

      assert Resolver.resolve({:system, :boolean, "DOES_NOT_EXIST"}) == {:error, reason}
    end

    test "for lists" do
      System.put_env("TESTENV", "1,2,3")
      assert Resolver.resolve({:system, :list, "TESTENV"}) == {:ok, ["1", "2", "3"]}
      assert Resolver.resolve({:system, :list, "DOES_NOT_EXIST", ["1", "2", "3"]}) == {:ok, ["1", "2", "3"]}

      reason = {
        :unresolved,
        "can not resolve key DOES_NOT_EXIST value via adapter Elixir.Confex.Adapters.SystemEnvironment"
      }

      assert Resolver.resolve({:system, :list, "DOES_NOT_EXIST"}) == {:error, reason}
    end

    test "custom resolvers" do
      System.put_env("TESTENV", "1,2,3")
      resolver = {__MODULE__, :do_cast, []}
      assert Resolver.resolve({:system, resolver, "TESTENV"}) == {:ok, "1,2,3"}
      assert Resolver.resolve({:system, resolver, "DOES_NOT_EXIST", "2,3,4"}) == {:ok, "2,3,4"}

      reason = {
        :unresolved,
        "can not resolve key DOES_NOT_EXIST value via adapter Elixir.Confex.Adapters.SystemEnvironment"
      }

      assert Resolver.resolve({:system, resolver, "DOES_NOT_EXIST"}) == {:error, reason}
    end

    test "custom adapters" do
      System.put_env("TESTENV", "foo")
      via_adapter = {:via, Confex.Adapters.SystemEnvironment}
      assert Resolver.resolve({via_adapter, "TESTENV"}) == {:ok, "foo"}
      assert Resolver.resolve({via_adapter, :string, "TESTENV"}) == {:ok, "foo"}
      assert Resolver.resolve({via_adapter, "DOES_NOT_EXIST", "foo"}) == {:ok, "foo"}
      assert Resolver.resolve({via_adapter, :string, "DOES_NOT_EXIST", "foo"}) == {:ok, "foo"}
    end
  end

  test "resolves with third-party adapters" do
    via_adapter = {:via, Confex.ResolverTest.TestAdapter}
    assert Resolver.resolve({via_adapter, "TESTENV"}) == {:ok, "TESTENV"}
    assert Resolver.resolve({via_adapter, :string, "TESTENV"}) == {:ok, "TESTENV"}
    assert Resolver.resolve({via_adapter, "DOES_NOT_EXIST", "foo"}) == {:ok, "DOES_NOT_EXIST"}
    assert Resolver.resolve({via_adapter, :string, "DOES_NOT_EXIST", "foo"}) == {:ok, "DOES_NOT_EXIST"}
  end

  def do_cast(value), do: {:ok, value}
end
