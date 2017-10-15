defmodule Confex.TypeTest do
  use ExUnit.Case, async: true
  alias Confex.Type
  doctest Confex.Type

  test "cast nil" do
    for type <- [:string, :integer, :float, :boolean, :atom, :module, :list] do
      assert {:ok, nil} == Type.cast(nil, type)
    end
  end

  test "cast string" do
    assert {:ok, "my_string"} == Type.cast("my_string", :string)
  end

  test "cast module" do
    assert {:ok, MyModule} == Type.cast("MyModule", :module)
    assert {:ok, :"Elixir.___@@*@#"} == Type.cast("___@@*@#", :module)
  end

  test "cast integer" do
    assert {:ok, 42} == Type.cast("42", :integer)
    assert {:ok, 0} == Type.cast("0", :integer)

    assert {:error, ~s/can not cast "0.5" to Integer, result contains binary remainder .5/} ==
      Type.cast("0.5", :integer)
    assert {:error, ~s/can not cast "42ab" to Integer, result contains binary remainder ab/} ==
      Type.cast("42ab", :integer)
    assert {:error, ~s/can not cast "abc" to Integer/} ==
      Type.cast("abc", :integer)
  end

  test "cast float" do
    assert {:ok, 42.5} == Type.cast("42.5", :float)
    assert {:ok, 0} == Type.cast("0", :float)
    assert {:ok, 7} == Type.cast("7", :float)

    assert {:error, ~s/can not cast "42.5ab" to Float, result contains binary remainder ab/} ==
      Type.cast("42.5ab", :float)
    assert {:error, ~s/can not cast "abc" to Float/} ==
      Type.cast("abc", :float)
  end

  test "cast atom" do
    assert {:ok, :my_atom} == Type.cast("my_atom", :atom)
    assert {:ok, :Myatom} == Type.cast("Myatom", :atom)
    assert {:ok, :"___@@*@#"} == Type.cast("___@@*@#", :atom)
  end

  test "cast boolean" do
    assert {:ok, true} == Type.cast("true", :boolean)
    assert {:ok, true} == Type.cast("tRue", :boolean)
    assert {:ok, true} == Type.cast("1", :boolean)
    assert {:ok, true} == Type.cast("yes", :boolean)

    assert {:ok, false} == Type.cast("false", :boolean)
    assert {:ok, false} == Type.cast("faLse", :boolean)
    assert {:ok, false} == Type.cast("0", :boolean)
    assert {:ok, false} == Type.cast("no", :boolean)

    assert {:error, ~s/can not cast "unknown" to boolean, expected values are 'true', 'false', '1', '0', 'yes' or 'no'/}
      == Type.cast("unknown", :boolean)
  end

  test "cast list" do
    assert {:ok, ["hello"]} == Type.cast("hello", :list)
    assert {:ok, ["1", "2", "3"]} == Type.cast("1,2,3", :list)
    assert {:ok, ["a", "b", "C"]} == Type.cast("a,b,C", :list)
    assert {:ok, ["a", "b", "C"]} == Type.cast(" a, b, C ", :list)
    assert {:ok, ["a", "b", "C", ""]} == Type.cast(" a, b, C, ", :list)
  end

  test "cast with {m,f,a}" do
    assert {:ok, "hello"} == Type.cast("hello", {__MODULE__, :do_cast, [:ok]})
    assert {:error, "generic reason"} == Type.cast("hello", {__MODULE__, :do_cast, [:error]})

    assert {:error, error} = Type.cast("hello", {__MODULE__, :do_cast, [:other_return]})
    assert error == "expected `Elixir.Confex.TypeTest.do_cast/2` to return either " <>
                    "`{:ok, value}` or `{:error, reason}` tuple, got: `:other_return`"
  end

  def do_cast(value, :ok),
    do: {:ok, value}
  def do_cast(_value, :error),
    do: {:error, "generic reason"}
  def do_cast(_value, _),
    do: :other_return
end
