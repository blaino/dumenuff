defmodule DumenuffEngine.Arena do
  alias DumenuffEngine.{Player, Decision, Room, Message}

  def new(), do: %{players: %{}, rooms: %{}}

  def add_player(arena, name, ethnicity) do
    case Player.new(ethnicity) do
      {:ok, player} -> put_in(arena, [Access.key(:players), Access.key(name, %{})], player)
      {:error, reason} -> {:error, reason}
    end
  end


end
