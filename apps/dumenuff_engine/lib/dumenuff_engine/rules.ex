defmodule DumenuffEngine.Rules do
  alias __MODULE__

  defstruct state: :not_initialized,
    num_humans: 0,
    humans_to_start: 2,
    timer: 180,
    num_rounds: nil,
    current_round: -1,
    matches_in_round: nil

  def new(), do: %Rules{}

  def check(%Rules{state: :not_initialized} = rules, :add_player) do
    rules = Map.update!(rules, :num_humans, &(&1 + 1))

    IO.inspect(rules, label: "rules / check / :add_player / rules: ")

    case all_humans_set?(rules) do
      true ->
        IO.puts("all_humans_set TRUE")
        {:ok, %Rules{rules | state: :humans_set}}
      false ->
        IO.puts("all_humans_set FALSE")
        {:ok, rules}
    end
  end

  def check(%Rules{state: :humans_set} = rules, :initialize) do
    IO.inspect(rules, label: "rules / check / :initialize / rules: ")
    {:ok, %Rules{rules | state: :initialized}}
  end

  def check(%Rules{state: :initialized} = rules, :start_game) do
    IO.inspect(rules, label: "rules / check / :start_game / rules: ")
    rules = Map.update!(rules, :current_round, &(&1 + 1))

    {:ok, %Rules{rules | state: :round_started}}
  end

  def check(%Rules{state: :round_started} = rules, :decide) do
    IO.inspect(rules, label: "rules / check / :decide / rules: ")
    rules = Map.update!(rules, :matches_in_round, &(&1 - 1))

    case matches_remain?(rules) do
      true -> {:ok, rules}
      false -> {:ok, %Rules{rules | state: :round_over}}
    end
  end

  def check(%Rules{state: :round_over} = rules, :next_round) do
    updated_rules = Map.update!(rules, :current_round, &(&1 + 1))
    IO.inspect(updated_rules, label: "rules / check / :next_round / updated_rules: ")

    case rounds_complete?(updated_rules) do
      true -> {:ok, %Rules{updated_rules | state: :game_over}}
      false -> {:ok, %Rules{updated_rules | state: :round_started}}
    end
  end


  # TODO reset when round over
  def check(%Rules{state: :round_started} = rules, :time_change) do
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

  defp matches_remain?(rules), do: rules.matches_in_round > 0

  defp rounds_complete?(rules), do: rules.current_round > rules.num_rounds
end
