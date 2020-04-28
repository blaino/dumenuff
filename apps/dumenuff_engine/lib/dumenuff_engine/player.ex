defmodule DumenuffEngine.Player do
  alias __MODULE__

  @enforce_keys [:ethnicity, :decisions, :done, :scores, :real_name]
  defstruct [:ethnicity, :decisions, :done, :scores, :real_name]

  @ethnicities [:bot, :human]

  def new(ethnicity, real_name \\ "") when ethnicity in @ethnicities do
    %Player{ethnicity: ethnicity, decisions: %{}, done: false, scores: %{}, real_name: real_name}
  end

  def new(_ethnicity, _real_name), do: {:error, :invalid_ethnicity}
end
