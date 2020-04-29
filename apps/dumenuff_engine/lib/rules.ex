defmodule DumenuffEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized,
            num_humans: 0,
            humans_to_start: 2,
            num_done: 0,
            timer: 180

  def new(), do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :add_player) do
    rules = Map.update!(rules, :num_humans, &(&1 + 1))

    IO.inspect(rules, label: "rules / check / rules: ")

    case all_humans_set?(rules) do
      true ->
        IO.puts("all_humans_set TRUE")
        {:ok, %Rules{rules | state: :humans_set}}
      false ->
        IO.puts("all_humans_set FALSE")
        {:ok, rules}
    end
  end

  def check(%Rules{state: :game_started} = rules, :done) do
    rules = Map.update!(rules, :num_done, &(&1 + 1))

    case all_humans_done?(rules) do
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

  def check(%Rules{state: :game_over} = rules, :time_change) do
    {:ok, rules}
  end

  def check(_state, _action), do: :error

  defp all_humans_set?(rules), do: rules.num_humans == rules.humans_to_start

  defp all_humans_done?(rules), do: rules.num_done == rules.num_humans
end
