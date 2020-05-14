defmodule DumenuffInterfaceWeb.GameView do
  use DumenuffInterfaceWeb, :view

  alias DumenuffEngine.{Game, Matchup}

  def get_room(game, player_token) do
    matchup = Game.find_match(game, player_token)
    IO.inspect(matchup, label: "game_view / get_room / matchup")
    matchup
  end

  def done(game, player_token) do
    matchup = Game.find_match(game, player_token)
    done(matchup)
  end

  def done(%Matchup{status: :done}), do: true

  def done(_matchup), do: false

  def messages(game, player) do
    room = get_room(game, player)
    Enum.reverse(room.messages)
  end

  def score(game, player) do
    game.humans[player].score
  end

  def notification_sum({sum, _msg} = notification), do: sum

  def notification_msg({_sum, msg} = notification), do: msg

end
