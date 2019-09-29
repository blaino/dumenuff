defmodule DumenuffEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized,
    num_players: 0,
    players_to_start: 3

  def new(), do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :add_player) do
    rules = Map.update!(rules, :num_players, &(&1 + 1))
    case all_players_set?(rules) do
      true -> {:ok, %Rules{rules | state: :players_set}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, :init_rooms) do
    {:ok, %Rules{rules | state: :game_started}}
  end

  def check(_state, _action), do: :error

  defp all_players_set?(rules), do: rules.num_players == rules.players_to_start

end
