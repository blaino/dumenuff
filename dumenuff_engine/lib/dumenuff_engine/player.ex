defmodule DumenuffEngine.Player do
  alias __MODULE__

  @enforce_keys [:ethnicity, :decisions, :done]
  defstruct [:ethnicity, :decisions, :done]

  @ethnicities [:bot, :human]

  def new(ethnicity) when ethnicity in @ethnicities do
    %Player{ethnicity: ethnicity, decisions: [], done: false}
  end

  def new(_ethnicity), do: {:error, :invalid_ethnicity}
end
