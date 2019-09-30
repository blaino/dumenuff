defmodule DumenuffEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized,
    num_players: 0,
    players_to_start: 1,
    num_done: 0,
    timer: 10

  def new(), do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :add_player) do
    rules = Map.update!(rules, :num_players, &(&1 + 1))
    case all_players_set?(rules) do
      true -> {:ok, %Rules{rules | state: :players_set}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :game_started} = rules, :done) do
    rules = Map.update!(rules, :num_done, &(&1 + 1))
    case all_players_done?(rules) do
      true -> {:ok, %Rules{rules | state: :game_over}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :game_started} = rules, :time_change) do
    rules = Map.update!(rules, :timer, &(&1 - 1))
    case rules.timer == 0 do
      true -> {:ok, %Rules{rules | state: :game_over}}
      false -> {:ok, rules}
    end
  end

  def check(_state, _action), do: :error

  defp all_players_set?(rules), do: rules.num_players == rules.players_to_start

  defp all_players_done?(rules), do: rules.num_done == rules.num_players

end
