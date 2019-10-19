defmodule DumenuffInterfaceWeb.GameView do
  use DumenuffInterfaceWeb, :view

  def get_rooms(state, player_token) do
    player_rooms = Enum.filter(state.rooms, fn {_k, v} ->
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

  def decision_checked(game_state, player, opponent, decision) do
    decisions = game_state.players[player].decisions
    if decisions[opponent] == decision, do: "checked"
  end
end
