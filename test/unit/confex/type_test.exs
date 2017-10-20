defmodule Confex.TypeTest do
  use ExUnit.Case, async: true
  alias Confex.Type
  doctest Confex.Type

  test "cast nil" do
    for type <- [:string, :integer, :float, :boolean, :atom, :module, :list, {M, :f, []}] do
      assert Type.cast(nil, type) == {:ok, nil}
    end
  end

  test "cast string" do
    assert Type.cast("my_string", :string) == {:ok, "my_string"}
  end

  test "cast module" do
    assert Type.cast("MyModule", :module) == {:ok, MyModule}
    assert Type.cast("___@@*@#", :module) == {:ok, :"Elixir.___@@*@#"}
  end

  test "cast integer" do
    assert Type.cast("42", :integer) == {:ok, 42}
    assert Type.cast("0", :integer) == {:ok, 0}

    reason = ~s/can not cast "0.5" to Integer, result contains binary remainder .5/
    assert Type.cast("0.5", :integer) == {:error, reason}

    reason = ~s/can not cast "42ab" to Integer, result contains binary remainder ab/
    assert Type.cast("42ab", :integer) == {:error, reason}

    assert Type.cast("abc", :integer) == {:error, ~s/can not cast "abc" to Integer/}
  end

  test "cast float" do
    assert Type.cast("42.5", :float) == {:ok, 42.5}
    assert Type.cast("0", :float) == {:ok, 0}
    assert Type.cast("7", :float) == {:ok, 7}

    reason = ~s/can not cast "42.5ab" to Float, result contains binary remainder ab/
    assert Type.cast("42.5ab", :float) == {:error, reason}

    assert Type.cast("abc", :float) == {:error, ~s/can not cast "abc" to Float/}
  end

  test "cast atom" do
    assert Type.cast("my_atom", :atom) == {:ok, :my_atom}
    assert Type.cast("Myatom", :atom) == {:ok, :Myatom}
    assert Type.cast("___@@*@#", :atom) == {:ok, :"___@@*@#"}
  end

  test "cast boolean" do
    assert Type.cast("true", :boolean) == {:ok, true}
    assert Type.cast("tRue", :boolean) == {:ok, true}
    assert Type.cast("1", :boolean) == {:ok, true}
    assert Type.cast("yes", :boolean) == {:ok, true}
    assert Type.cast("false", :boolean) == {:ok, false}
    assert Type.cast("faLse", :boolean) == {:ok, false}
    assert Type.cast("0", :boolean) == {:ok, false}
    assert Type.cast("no", :boolean) == {:ok, false}

    reason = ~s/can not cast "unknown" to boolean, expected values are 'true', 'false', '1', '0', 'yes' or 'no'/
    assert Type.cast("unknown", :boolean) == {:error, reason}
  end

  test "cast list" do
    assert Type.cast("hello", :list) == {:ok, ["hello"]}
    assert Type.cast("1,2,3", :list) == {:ok, ["1", "2", "3"]}
    assert Type.cast("a,b,C", :list) == {:ok, ["a", "b", "C"]}
    assert Type.cast(" a, b, C ", :list) == {:ok, ["a", "b", "C"]}
    assert Type.cast(" a, b, C, ", :list) == {:ok, ["a", "b", "C", ""]}
  end

  test "cast with {m,f,a}" do
    assert Type.cast("hello", {__MODULE__, :do_cast, [:ok]}) == {:ok, "hello"}
    assert Type.cast("hello", {__MODULE__, :do_cast, [:error]}) == {:error, "generic reason"}

    reason =
      "expected `Elixir.Confex.TypeTest.do_cast/2` to return either " <>
        "`{:ok, value}` or `{:error, reason}` tuple, got: `:other_return`"

    assert Type.cast("hello", {__MODULE__, :do_cast, [:other_return]}) == {:error, reason}
  end

  def do_cast(value, :ok), do: {:ok, value}
  def do_cast(_value, :error), do: {:error, "generic reason"}
  def do_cast(_value, _), do: :other_return
end
