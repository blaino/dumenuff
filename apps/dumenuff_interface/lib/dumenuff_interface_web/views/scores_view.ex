defmodule DumenuffInterfaceWeb.ScoresView do
  use DumenuffInterfaceWeb, :view

  alias DumenuffEngine.{Player}

  def real_name(%Player{ethnicity: :bot} = player) do
    "a bot"
  end

  def real_name(%Player{ethnicity: :human} = player) do
    player.real_name
  end

  def score(%Player{scores: scores} = _player) do
    sum_scores(scores)
  end

  def sort_by_score(players) do
    {name, %Player{scores: scores} = player} = Enum.at(players, 0)
    Enum.sort_by(players, fn {name, %Player{scores: scores}} = player -> -sum_scores(scores) end)
  end

  def sum_scores(scores) do
    Enum.reduce(scores, 0, fn({_k, v}, acc) -> v + acc end)
  end
end
