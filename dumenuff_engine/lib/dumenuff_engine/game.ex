defmodule DumenuffEngine.Game do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias DumenuffEngine.{Player, Decision, Room, Message, Combinations, Rules}

  @ethnicities [:bot, :human]
  @bot_names ["thx1138", "zorgo"]

  ########
  # API
  #
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

  # TODO consider checking if room_name is in game.rooms
  # TODO protect against message with from to not matching those in room
  def post(game, room_name, %Message{} = message) when is_binary(room_name) do
    GenServer.call(game, {:post, room_name, message})
  end

  # TODO protect against decision not matching players
  def decide(game, player_name, %Decision{} = decision) when is_binary(player_name) do
    GenServer.call(game, {:decide, player_name, decision})
  end

  def done(game, player_name) when is_binary(player_name) do
    GenServer.call(game, {:done, player_name})
  end

  ########
  # Handlers
  #
  def handle_info({:set_state, name}, state_data) do
    {:noreply, state_data}
  end

  def handle_info(:time_change, state_data) do
    {:ok, rules} = Rules.check(state_data.rules, :time_change)
    state_data = update_rules(state_data, rules)
    if state_data.rules.state != :game_over do
      Process.send_after(self(), :time_change, 1000)
    end
    {:noreply, state_data}
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

  def handle_call({:post, room_name, message}, _from, state_data) do
      state_data
      |> update_in_messages(room_name, message)
      |> reply_success(:ok)
  end

  def handle_call({:decide, player, decision}, _from, state_data) do
    state_data
    |> put_in_decision(player, decision)
    |> reply_success(:ok)
  end

  def handle_call({:done, player_name}, _from, state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :done)
      do
      state_data
      |> set_done(player_name)
      |> update_rules(rules)
      |> reply_success(:ok)
      else
        :error -> {:reply, :error, state_data}
    end
  end

  ########
  # Private Helpers
  #
  defp bot_names(), do: @bot_names

  defp check_players_set(game) do
    case game.rules.state == :players_set do
      true ->
        game = game
        |> init_bots
        |> init_rooms
        |> start_game
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

  defp start_game(game) do
    Process.send_after(self(), :time_change, 1000)
    update_rules(game, %Rules{game.rules | state: :game_started})
  end

  defp put_in_player(game, player, name) do
    put_in(game, [Access.key(:players), Access.key(name, %{})], player)
  end

  defp update_in_messages(game, room, message) do
    update_in(game, [Access.key(:rooms), Access.key(room), Access.key(:messages)],
      &([message | &1]))
  end

  defp put_in_decision(game, player, decision) do
    put_in(game, [Access.key(:players), Access.key(player), Access.key(:decisions)], decision)
  end

  defp set_done(game, player) do
    put_in(game, [Access.key(:players), Access.key(player), Access.key(:done)], true)
  end

  defp via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  defp fresh_state(name) do
    %{registered_name: name, players: %{}, rooms: %{}, rules: %Rules{}}
  end

  defp update_rules(state_data, rules), do: %{state_data | rules: rules}

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end


end
