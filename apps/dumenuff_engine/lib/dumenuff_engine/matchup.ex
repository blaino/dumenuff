defmodule DumenuffEngine.Matchup do
  alias __MODULE__

  defstruct [:player1, :player2, :messages]

  def new(name1, name2) do
    %Matchup{player1: name1, player2: name2, messages: []}
  end
end
