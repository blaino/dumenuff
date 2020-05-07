defmodule DumenuffInterfaceWeb.GameView do
  use DumenuffInterfaceWeb, :view

  alias DumenuffEngine.Game

  def get_room(game, player_token) do
    matchup = Game.find_match(game, player_token)
    IO.inspect(matchup, label: "game_view / get_room / matchup")
    matchup
  end

  def messages(_game_state, player, opponent) when is_nil(player) or is_nil(opponent), do: []

  def messages(game_state, player, opponent) do
    # room_name = Game.room_by_players(game_state, player, opponent)
    # Enum.reverse(game_state.rooms[room_name].messages)
    ["foo", "bar", "baz"]
  end
end
