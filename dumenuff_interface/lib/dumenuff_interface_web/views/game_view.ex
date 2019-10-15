defmodule DumenuffInterfaceWeb.GameView do
  use DumenuffInterfaceWeb, :view

  def get_rooms(state, player_token) do
    player_rooms = Enum.filter(state.rooms, fn {k, v} ->
      v.player1 == player_token || v.player2 == player_token
    end)

    Enum.map(player_rooms, fn {k, v} ->
      if v.player1 == player_token do
        v.player2
      else
        v.player1
      end
    end)
  end

  def checked(room, current_room) do
    if room == current_room do
      "checked"
    end
  end

end
