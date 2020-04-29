defmodule DumenuffEngine.Matchup do
  alias __MODULE__

  @enforce_keys [:player1, :player2, :status]
  defstruct [:player1, :player2, :status]

  def new(name1, name2) do
    %Matchup{player1: name1, player2: name2, status: :pending}
  end
end
