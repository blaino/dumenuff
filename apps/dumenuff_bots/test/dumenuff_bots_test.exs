defmodule DumenuffBotsTest do
  use ExUnit.Case
  doctest DumenuffBots

  test "greets the world" do
    assert DumenuffBots.hello() == :world
  end
end
