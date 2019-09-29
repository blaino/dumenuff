defmodule DumenuffEngine.Game do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias DumenuffEngine.{Player, Decision, Room, Message, Combinations, Rules}

  @ethnicities [:bot, :human]
  @timeout 60 * 60 * 24 * 1000

  def bot_names(), do: ["thx1138", "zorgo"]

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def init(name) do
    send(self(), {:set_state, name})
    {:ok, fresh_state(name)}
  end

  def add_player(game, name, ethnicity) when is_binary(name) and ethnicity in @ethnicities do
    GenServer.call(game, {:add_player, name, ethnicity})
  end


  def handle_info({:set_state, name}, state_data) do
    {:noreply, state_data, @timeout}
  end

  def handle_call({:add_player, name, ethnicity}, _from, state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player)
      do
      state_data
      |> put_in_player(Player.new(ethnicity), name)
      |> update_rules(rules)
      |> check_players_set
      |> reply_success(:ok)
      else
        :error -> {:reply, :error, state_data}
    end
  end





  # TODO consider sending in a Message as opposed to building it here
  def post(game, room, from, to, msg) do
    update_in(game, [Access.key(:rooms), Access.key(room), Access.key(:messages)],
      &([Message.new(from, to, msg) | &1]))
  end

  def decide(game, player, opponent, decision) do
    case Decision.new(opponent, decision) do
      {:ok, decision} ->
        put_in(game, [Access.key(:players), Access.key(player), Access.key(:decisions)], decision)
      {:error, reason} -> {:error, :reason}
    end
  end

  defp check_players_set(game) do
    case game.rules.state == :players_set do
      true ->
        game = game
        |> init_bots
        |> init_rooms
      false ->
        game
    end
  end

  defp init_bots(game) do
    Enum.reduce(bot_names(), game,
      fn name, acc -> put_in_player(acc, Player.new(:bot), name) end)
  end

  defp init_rooms(game) do
    # TODO filter out bot on bot pairs
    player_list = Map.keys(game.players)
    combos = Combinations.combinations(player_list, 2)
    rooms = Map.new(combos, fn x -> {Enum.join(x, "_"), Room.new(List.first(x), List.last(x))} end)
    put_in(game.rooms, rooms)
  end

  defp put_in_player(game, player, name) do
    put_in(game, [Access.key(:players), Access.key(name, %{})], player)
  end

  defp via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  defp fresh_state(name) do
    %{registered_name: name, players: %{}, rooms: %{}, rules: %Rules{}}
  end

  defp update_rules(state_data, rules), do: %{state_data | rules: rules}

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data, @timeout}
  end


end
