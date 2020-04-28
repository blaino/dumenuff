defmodule DumenuffInterfaceWeb.GameView do
  use DumenuffInterfaceWeb, :view

  alias DumenuffEngine.Game

  def get_rooms(state, player_token) do
    player_rooms =
      Enum.filter(state.rooms, fn {_k, v} ->
        v.player1 == player_token || v.player2 == player_token
      end)

    Enum.map(player_rooms, fn {_k, v} ->
      if v.player1 == player_token do
        v.player2
      else
        v.player1
      end
    end)
  end

  def room_checked(room, current_room) do
    if room == current_room do
      "checked"
    end
  end

  def decision_checked(_game_state, player, opponent, _decision)
      when is_nil(player) or is_nil(opponent),
      do: nil

  def decision_checked(game_state, player, opponent, decision) do
    decisions = game_state.players[player].decisions
    if decisions[opponent] == decision, do: "checked"
  end

  def messages(_game_state, player, opponent) when is_nil(player) or is_nil(opponent), do: []

  def messages(game_state, player, opponent) do
    room_name = Game.room_by_players(game_state, player, opponent)
    Enum.reverse(game_state.rooms[room_name].messages)
  end
end
