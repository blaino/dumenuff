defmodule DumenuffEngine.Matchup do
  alias __MODULE__

  defstruct [:player1, :player2, :messages, :status]

  def new(name1, name2) do
    %Matchup{player1: name1, player2: name2, messages: [], status: :pending}
  end
end
