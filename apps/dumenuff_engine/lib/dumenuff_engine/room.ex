defmodule DumenuffEngine.Room do
  alias __MODULE__

  @enforce_keys [:player1, :player2, :messages]
  defstruct [:player1, :player2, :messages]

  def new(name1, name2) do
    %Room{player1: name1, player2: name2, messages: []}
  end
end
