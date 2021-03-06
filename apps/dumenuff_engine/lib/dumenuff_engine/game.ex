defmodule DumenuffEngine.Game do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias DumenuffEngine.{Player, Matchup, Combinations, Rules}

  @timeout 60 * 60 * 24 * 1000
  @pubsub_name :dumenuff

  ########
  # API
  #

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  def pid_from_name(name) do
    name
    |> via_tuple()
    |> GenServer.whereis()
  end

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def init(name) do
    send(self(), {:set_state, name})
    {:ok, fresh_state(name)}
  end

  def get_state(game) do
    GenServer.call(game, {:get_state})
  end

  def add_player(game, name) when is_binary(name) do
    IO.inspect(name, label: "game / add_player / name: ")
    GenServer.call(game, {:add_player, name})
  end

  def post(game, player, message) do
    GenServer.call(game, {:post, player, message})
  end

  # decide(game, "Blaine", :bots) = Blaine's opponent is a bot
  def decide(game, name, decision) do
    GenServer.call(game, {:decide, name, decision})
  end

  ########
  # Handlers
  #

  def terminate({:shutdown, :timeout}, state_data) do
    :ets.delete(:game_state, state_data.player1.name)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  def handle_info(:timeout, state_data), do: {:stop, {:shutdown, :timeout}, state_data}

  def handle_info({:set_state, name}, _state_data) do
    state_data =
      case :ets.lookup(:game_state, name) do
        [] -> fresh_state(name)
        [{_key, state}] -> state
      end

    :ets.insert(:game_state, {name, state_data})
    {:noreply, state_data, @timeout}
  end

  def handle_info(:time_change, state_data) do
    {:ok, rules} = Rules.check(state_data.rules, :time_change)
    state_data = update_rules(state_data, rules)

    if state_data.rules.state == :game_over do
      Phoenix.PubSub.broadcast(@pubsub_name, state_data.registered_name, {:game_over})
    else
      Process.send_after(self(), :time_change, 1000)
    end

    # Publish game state every second
    Phoenix.PubSub.broadcast(@pubsub_name, state_data.registered_name, {:tick, state_data})

    {:noreply, state_data, @timeout}
  end

  def handle_call({:get_state}, _from, state_data) do
    reply_success(state_data, :ok)
  end

  def handle_call({:add_player, name}, _from, state_data) do
    IO.inspect(name, label: "game / handle_call / :add_player / name: ")
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player) do
      IO.puts("successfully added player")
      state_data
      |> put_in_player(Player.new(name), name)
      |> update_rules(rules)
      |> initialize
      |> IO.inspect(label: "game / handle_call / :add_player / state_data")
      |> start_game
      |> reply_success(:ok)
    else
      :error ->
        IO.puts("failed to add player")
        {:reply, :error, state_data}
    end
  end

  def handle_call({:post, player, message}, _from, game) do
    game
    |> update_messages(player, message)
    |> reply_success(:ok)
  end

  def handle_call({:decide, player, decision}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, :decide) do
      game
      |> update_rules(rules)
      |> update_score(player, decision)
      |> update_status(player)
      |> IO.inspect(label: "game / handle_call / :decide / update_score / game")
      |> next_round
      |> reply_success(:ok)
    else
      :error ->
        IO.puts("failed to decide")
      {:reply, :error, game}
    end
  end

  # def remove_matchup(game, player) do
  #   # TODO
  #   game
  # end

  # TODO seems harder than it should be
  def room_by_players(state_data, p1, p2) do
    rooms =
      Enum.filter(state_data.rooms, fn {_room_name, r} ->
        (r.player1 == p1 and r.player2 == p2) or (r.player1 == p2 and r.player2 == p1)
      end)

    {room_name, _room} = Enum.at(rooms, 0)
    room_name
  end

  ########
  # Private Helpers
  #

  defp initialize(game) do
    with {:ok, rules} <- Rules.check(game.rules, :initialize) do
      game
      |> update_rules(rules)
      |> init_bots
      |> init_rounds
    else
      :error -> game
    end
  end

  defp start_game(game) do
    IO.inspect(game.rules, label: "game / start_game / rules: ")
    with {:ok, rules} <- Rules.check(game.rules, :start_game) do
      # Process.send_after(self(), :time_change, 1000)
      Phoenix.PubSub.broadcast(@pubsub_name, game.registered_name, {:round_started})
      # greet(game)
      game
      |> update_rules(rules)
      |> init_match

    else
      :error -> game
    end
  end

  defp next_round(game) do
    with {:ok, rules} <- Rules.check(game.rules, :next_round) do
      IO.inspect(game.rules, label: "game / next_round / rules after check")
      game = update_rules(game, rules)
      if game.rules.state == :game_over do
        Phoenix.PubSub.broadcast(@pubsub_name, game.registered_name, {:game_over})
        game
      else
        game = update_rules(game, matches_in_round(game))
        IO.inspect(game, label: "game / next_round / game after updates")
        Phoenix.PubSub.broadcast(@pubsub_name, game.registered_name, {:round_started})
        game
      end
    else
      :error -> game
    end
  end

  # TODO match on rules and rounds in arguments?
  # TODO return a game instead of rules so above can be chained/piped
  def matches_in_round(game) do
    %Rules{
      game.rules | matches_in_round: Enum.count(Enum.at(game.rounds, game.rules.current_round))}
  end

  def init_bots(game) do
    bot_list = ["bot1", "bot2"]
    bots = Map.new(bot_list, fn x -> {x, Player.new(x)} end)
    put_in(game.bots, bots)
  end

  def init_rounds(game) do
    matchups = gen_matchups(game)
    rounds = gen_rounds(matchups, [])

    game = put_in(game.rounds, rounds)
    game = update_rules(game, %Rules{game.rules | num_rounds: Enum.count(rounds)})

    IO.inspect(game, label: "game / init_rounds / game")
  end

  def init_match(game) do
    update_rules(game, matches_in_round(game))
  end

  def gen_matchups(game) do
    player_list = Map.keys(Map.merge(game.humans, game.bots))
    combos = Combinations.combinations(player_list, 2)
    bot_list = Map.keys(game.bots)

    Enum.map(combos, fn combo -> Matchup.new(List.first(combo), List.last(combo)) end)
    |> Enum.reject(fn matchup -> bot_on_bot?(matchup, bot_list) end)
  end

  def gen_rounds([], rounds), do: rounds

  def gen_rounds(matchups, rounds) do
    remaining = Enum.reject(matchups, fn m -> Enum.member?(List.flatten(rounds), m) end)
    if Enum.empty?(remaining) do
      gen_rounds(remaining, rounds)
    else
      gen_rounds(remaining, [gen_round(remaining, []) | rounds])
    end
  end

  def gen_round([matchup | tail], round) do
    gen_round(reject_matched(matchup, tail), [matchup | round])
  end

  def gen_round([], round), do: round

  def reject_matched(matchup, tail) do
    Enum.reject(
      tail,
      fn m -> MapSet.size(MapSet.intersection(players(matchup), players(m))) > 0 end)
  end

  # TODO move to matchup.ex
  def players(matchup) do
    MapSet.new([matchup.player1, matchup.player2])
  end

  def bot_on_bot?(matchup, bot_list) do
    Enum.member?(bot_list, matchup.player1) && Enum.member?(bot_list, matchup.player2)
  end

  # messages - update the game
  def update_messages(game, player, message) do
    Map.update!(game, :rounds, fn _ -> update_messages_helper(game, player, message) end)
  end

  # messages - update the round
  def update_messages_helper(game, player, message) do
    match_index = Enum.find_index(current_round(game),
      fn m -> m.player1 == player || m.player2 == player end)

    List.update_at(game.rounds, game.rules.current_round,
      fn round -> umh(round, match_index, message) end)
  end

  # messages - update the matchup
  def umh(round, index, message) do
    List.update_at(round, index,
      fn matchup -> %{matchup | messages: [message | matchup.messages]} end )
  end

  # Why is this so hard?
  def update_score(game, player, decision) do
    {_, updated_game} = update_score_helper(game, player, decision)
    updated_game
  end

  def update_score_helper(game, player, decision) do
    opponent = find_opponent(game, player)
    correct? = correct_decision?(game, opponent, decision)

    IO.inspect(game, label: "game / update_score_helper / game")

    Phoenix.PubSub.broadcast(
      @pubsub_name, game.registered_name, {:notify, {player, decision, correct?}})

    if correct? do
      # Map.update!(game.humans[player], :score, &(&1 + 1))
      get_and_update_in(
        game,
        [Access.key!(:humans), Access.key!(player), Access.key!(:score)], fn s -> {s, s + 1} end)
    else
      # Map.update!(game.humans[player], :score, &(&1 - 1))
      get_and_update_in(
        game,
        [Access.key!(:humans), Access.key!(player), Access.key!(:score)], fn s -> {s, s - 1} end)
    end
  end

  # status - update the game
  def update_status(game, player) do
    Map.update!(game, :rounds, fn _ -> update_status_helper(game, player) end)
  end

  # status - update the round
  def update_status_helper(game, player) do
    match_index = Enum.find_index(current_round(game),
      fn m -> m.player1 == player || m.player2 == player end)

    List.update_at(game.rounds, game.rules.current_round,
      fn round -> ush(round, match_index) end)
  end

  # status - update the matchup
  def ush(round, index) do
    List.update_at(round, index,
      fn matchup -> %{matchup | status: :done} end )
  end

  def find_opponent(game, player) do
    match = find_match(game, player)
    find_opponent_from_match(match, player)
  end

  def find_opponent_from_match(match, player) do
    if match.player1 == player do
      match.player2
    else
      match.player1
    end
  end

  def correct_decision?(game, opponent, decision) do
    game
    |> Map.get(decision)
    |> Map.keys
    |> Enum.member?(opponent)
  end

  def find_match(game, player) do
    Enum.find(current_round(game), fn m -> m.player1 == player || m.player2 == player end)
  end

  def current_round(game) do
    Enum.at(game.rounds, game.rules.current_round)
  end

  defp put_in_player(game, player, name) do
    put_in(game, [Access.key(:humans), Access.key(name, %{})], player)
  end

  defp fresh_state(name) do
    %{registered_name: name, humans: %{}, bots: %{}, rounds: %{}, rules: %Rules{}}
  end

  defp update_rules(state_data, rules), do: %{state_data | rules: rules}

  defp reply_success(state_data, reply) do
    :ets.insert(:game_state, {state_data.registered_name, state_data})

    # This is potentially a big change if there are lots of consumers
    {:reply, {reply, state_data}, state_data}
  end

  def bot_in_room?(game, room) do
    bot_names = Map.keys(game.bots)
    Enum.member?(bot_names, room.player1) || Enum.member?(bot_names, room.player2)
    cond do
      Enum.member?(bot_names, room.player1) -> room.player1
      Enum.member?(bot_names, room.player2) -> room.player2
      true -> false
    end
  end

end
