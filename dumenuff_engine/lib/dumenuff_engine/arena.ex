defmodule DumenuffEngine.Arena do
  alias DumenuffEngine.{Player, Decision, Room, Message}

  def new(), do: %{players: %{}, rooms: %{}}

  def add_player(arena, name, ethnicity) do
    case Player.new(ethnicity) do
      {:ok, player} -> put_in(arena, [Access.key(:players), Access.key(name, %{})], player)
      {:error, reason} -> {:error, reason}
    end
  end

  def init_rooms(arena) do
    player_list = Map.keys(arena.players)
    combos = combinations(player_list, 2)
    rooms = Map.new(combos, fn x -> {Enum.join(x, "_"), Room.new(List.first(x), List.last(x))} end)
    put_in(arena.rooms, rooms)
  end

  def combinations(list, num)
  def combinations(_list, 0), do: [[]]
  def combinations(list = [], _num), do: list
  def combinations([head | tail], num) do
    Enum.map(combinations(tail, num - 1), &[head | &1]) ++
      combinations(tail, num)
  end
end
