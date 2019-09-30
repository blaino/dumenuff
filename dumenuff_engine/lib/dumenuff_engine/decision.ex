defmodule DumenuffEngine.Decision do
  alias __MODULE__

  @enforce_keys [:opponent_name, :decision]
  defstruct [:opponent_name, :decision]

  @decisions [:bot, :human, :undecided]

  def new(opponent_name, decision \\ :undecided)

  def new(opponent_name, decision) when decision in @decisions do
    {:ok, %Decision{opponent_name: opponent_name, decision: decision}}
  end

  def new(_opponent_name, _decision), do: {:error, :invalid_decision}
end
