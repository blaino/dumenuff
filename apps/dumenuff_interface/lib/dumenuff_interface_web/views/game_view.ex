defmodule DumenuffInterfaceWeb.GameView do
  use DumenuffInterfaceWeb, :view

  alias DumenuffEngine.Game

  def get_room(game, player_token) do
    matchup = Game.find_match(game, player_token)
    IO.inspect(matchup, label: "game_view / get_room / matchup")
    matchup
  end

  def messages(game, player) do
    room = get_room(game, player)
    Enum.reverse(room.messages)
  end

end
