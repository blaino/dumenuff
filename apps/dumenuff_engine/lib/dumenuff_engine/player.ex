defmodule DumenuffEngine.Player do
  alias __MODULE__

  @enforce_keys [:name]
  defstruct [:name, :score]

  def new(name) do
    %Player{name: name, score: 0}
  end
end
