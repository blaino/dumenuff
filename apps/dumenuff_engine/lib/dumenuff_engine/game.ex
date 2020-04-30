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
      |> check_humans_set
      |> reply_success(:ok)
    else
      :error ->
        IO.puts("failed to add player")
        {:reply, :error, state_data}
    end
  end

  def handle_call({:decide, player, decision}, _from, state_data) do
    state_data
    |> update_score(player, decision)
    |> reply_success(:ok)
  end

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

  defp check_humans_set(game) do
    case game.rules.state == :humans_set do
      true ->
        game
        |> init_bots
        |> init_rounds
        |> start_game

      false ->
        game
    end
  end

  def init_bots(game) do
    bot_list = ["bot1", "bot2"]
    bots = Map.new(bot_list, fn x -> {x, Player.new(x)} end)
    put_in(game.bots, bots)
  end

  def init_rounds(game) do
    matchups = gen_matchups(game)
    rounds = gen_rounds(matchups, [])
    put_in(game.rounds, rounds)
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

  # TODO
  defp update_score(game, player, decision) do
    opponent = decision.opponent_name
    guess = decision.decision
    opponent_ethnicity = game.humans[opponent].ethnicity

    put_in(
      game,
      [Access.key(:humans), Access.key(player), Access.key(:scores), Access.key(opponent)],
      score(guess, opponent_ethnicity)
    )
  end

  defp start_game(game) do
    Process.send_after(self(), :time_change, 1000)
    Phoenix.PubSub.broadcast(@pubsub_name, game.registered_name, {:game_started})
    # greet(game)
    update_rules(game, %Rules{game.rules | state: :game_started})
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

  defp greet(game) do
    Enum.each(game.rooms, fn {room_name, room} ->
      if :rand.uniform > 0.55 do
        cond do
          game.humans[room.player1].ethnicity == :bot and
          game.humans[room.player2].ethnicity == :human ->
            {:ok, message} = Message.new(room.player2, room.player1, "xxxgreetingxxx")
            Phoenix.PubSub.broadcast!(@pubsub_name, game.registered_name, {:bot_reply, room_name, message})

            game.humans[room.player1].ethnicity == :human and
          game.humans[room.player2].ethnicity == :bot ->
            {:ok, message} = Message.new(room.player1, room.player2, "xxxgreetingxxx")
            Phoenix.PubSub.broadcast!(@pubsub_name, game.registered_name, {:bot_reply, room_name, message})
          true ->
            "blah"
        end
      end
    end)
  end

  # TODO
  defp score(guess, opponent_ethnicity) do
    cond do
      guess == :undecided -> 0
      guess == opponent_ethnicity -> 1
      guess != opponent_ethnicity -> -1
    end
  end
end
