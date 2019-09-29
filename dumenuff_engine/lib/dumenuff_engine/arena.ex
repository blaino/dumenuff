defmodule DumenuffEngine.Arena do
  alias DumenuffEngine.{Player, Decision, Room, Message, Combinations}

  def bot_names(), do: ["thx1138", "zorgo"]

  def new(), do: %{players: %{}, rooms: %{}}

  def add_player(arena, name, ethnicity) do
    put_in_player(Player.new(ethnicity), name, arena)
  end

  def init_bots(arena) do
    # Enum.reduce(["thx-1138", "borg"], arena,
    Enum.reduce(bot_names(), arena,
      fn name, acc -> put_in_player(Player.new(:bot), name, acc) end)
  end

  def init_rooms(arena) do
    # TODO filter out bot on bot pairs
    player_list = Map.keys(arena.players)
    combos = Combinations.combinations(player_list, 2)
    rooms = Map.new(combos, fn x -> {Enum.join(x, "_"), Room.new(List.first(x), List.last(x))} end)
    put_in(arena.rooms, rooms)
  end

  # TODO consider sending in a Message as opposed to building it here
  def post(arena, room, from, to, msg) do
    update_in(arena, [Access.key(:rooms), Access.key(room), Access.key(:messages)],
      &([Message.new(from, to, msg) | &1]))
  end

  def decide(arena, player, opponent, decision) do
    case Decision.new(opponent, decision) do
      {:ok, decision} ->
        put_in(arena, [Access.key(:players), Access.key(player), Access.key(:decisions)], decision)
      {:error, reason} -> {:error, :reason}
    end
  end

  defp put_in_player(player, name, arena) do
    put_in(arena, [Access.key(:players), Access.key(name, %{})], player)
  end

end
