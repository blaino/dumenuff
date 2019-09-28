defmodule DumenuffEngineTest do
  use ExUnit.Case
  doctest DumenuffEngine

  test "greets the world" do
    assert DumenuffEngine.hello() == :world
  end
end
