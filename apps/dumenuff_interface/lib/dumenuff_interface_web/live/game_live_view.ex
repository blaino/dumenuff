defmodule DumenuffInterfaceWeb.GameLiveView do
  use Phoenix.LiveView

  alias DumenuffEngine.{Game, Decision, Message, Matchup}

  @pubsub_name :dumenuff

  def render(%{game: _game, error: nil} = assigns) do
    Phoenix.View.render(DumenuffInterfaceWeb.GameView, "show.html", assigns)
  end

  def render(%{error: _error} = assigns) do
    ~L"""
    <section class="game">
      <div data-error class="alert alert-info">
        <%= @error %>
      </div>
    </section>
    """
  end

  def render(%{game: nil} = assigns) do
    ~L"""
    <section class="game">
      <div class="msg">
        Connecting...
      </div>
    </section>
    """
  end


  def mount(session, socket) do
    IO.puts("live / mount")
    IO.inspect(session, label: "live / mount / session: ")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(@pubsub_name, session.game_name)
      send(self(), {:add_player, session.game_pid, session.player_name})
    end

    IO.inspect(session.game_pid, label: "live / mount / session.game_pid")
    IO.inspect(session.game_name, label: "live / mount / session.game_name")

    {:ok, assign(socket,
         game: nil,
         game_pid: session.game_pid, # tic tac doesn't have this
         game_name: session.game_name,
         player_token: session.player_name, # was player in tic tac
         current_room: nil,
         message: nil,
         error: nil,
         notification: nil,
     )}
  end

  def handle_info({:add_player, game_pid, player_name}, socket) do
    IO.inspect(game_pid, label: "live / handle_info / :add_player / game_pid")
    case Game.add_player(game_pid, player_name) do
      {:ok, game_state} ->
        IO.puts("live / handle_info / :add_player / success")
        IO.inspect(game_state.rules, label: "live / handle_info / :add_player / game_state.rules")
        IO.inspect(game_state.registered_name, label: "live / handle_info / :add_player / game_state.registered_name")
        {:noreply, assign(socket, game: game_state, game_pid: game_pid)}
      :error ->
        IO.puts("live / handle_info / :add_player / fail")
        {:noreply, socket}
    end
  end

  def handle_info(
        {:round_started},
        %{assigns: %{player_token: player_token, game_pid: game_pid}} = socket
      ) do

    IO.inspect(player_token, label: "live / handle_info / :round_started / player_token: ")
    IO.inspect(game_pid, label: "live / handle_info / :round_started / game_pid: ")

    {:ok, game_state} = Game.get_state(game_pid)
    room = DumenuffInterfaceWeb.GameView.get_room(game_state, player_token)
    greet(game_state, room)

    {:noreply,
      socket
      |> assign(:game, game_state)
      |> assign(:current_room, room)}
  end

  def handle_info(
        {:notify, {player, decision, correct?}},
        %{assigns: %{player_token: player_token, current_room: %Matchup{player1: p1, player2: p2}}} = socket
      ) when (p1 == player or p2 == player) do

    notification = notification_message({player_token, player, decision, correct?})

    Process.send_after(self(), {:notify_clear}, 3000)

    {:noreply,
      socket
      |> assign(:notification, notification)}
  end

  def handle_info({:notify, _}, socket), do: {:noreply, socket}

  def notification_message({player_token, player, :humans, true}) when player_token == player do
    {"Right!",  "You're opponent is a human. +1"}
  end

  def notification_message({player_token, player, :bots, true}) when player_token == player do
    {"Right!", "You're opponent is a bot. +1"}
  end

  def notification_message({player_token, player, :humans, false}) when player_token == player do
    {"Wrong!", "You're opponent is a bot. -1"}
  end

  def notification_message({player_token, player, :bots, false}) when player_token == player do
    {"Wrong!", "You're opponent is a human. -1"}
  end

  def notification_message({player_token, player, decision, true})
  when player_token != player do
    {"Boo.", "Your opponent thinks you're a human and gets a point"}
  end

  def notification_message({player_token, player, decision, false})
  when player_token != player do
    {"Nice.", "Your opponent thinks you're a bot and loses a point"}
  end


  def handle_info({:notify_clear}, socket) do
    IO.inspect(socket.assigns, label: "game_live_view / :notify_clear / socket.assigns")

    {:noreply,
      socket
      |> assign(:notification, nil)}
  end

  def handle_info(
        {:new_message},
        %{assigns: %{game_pid: game_pid}} = socket
      ) do
    {:ok, game_state} = Game.get_state(game_pid)

    {:noreply,
     socket
     |> assign(:game, game_state)}
  end

  def handle_info(
        {:game_over},
        %{assigns: %{game_pid: game_pid, game_name: game_name}} = socket
      ) do
    {:ok, game_state} = Game.get_state(game_pid)

    IO.inspect(game_name, label: "live / handle_info / :game_over / game_name: ")

    {:noreply,
     socket
     |> assign(:game, game_state)
     |> redirect(to: DumenuffInterfaceWeb.Router.Helpers.scores_path(DumenuffInterfaceWeb.Endpoint, :show, game_name))}
  end

  # when: only send the reply to the right human
  def handle_info(
    {:bot_reply, current_room, %{from: from} = human_message},
    # %{assigns: %{player_token: player_token}} = socket) when player_token == from do
    %{assigns: %{player_token: player_token}} = socket) do
    {:ok, reply} = NodeJS.call("index", [human_message.content])

    IO.inspect(reply, label: "live / handle_info / :bot_reply / NodeJs / reply")

    charCount = String.length(reply)
    num_players_proxy = 10
    delay = 120 * charCount + (:rand.uniform(3000) * num_players_proxy)

    bot = Game.find_opponent_from_match(current_room, player_token)

    {:ok, bot_message} = Message.new(bot, reply)

    Process.send_after(self(), {:bot_reply_delay, bot, bot_message}, delay)

    {:noreply, socket}
  end

  def handle_info({:bot_reply, _current_room, _human_message}, socket) do
    IO.puts(":bot_reply did not match")
    {:noreply, socket}
  end

  # TODO new posting regime!
  def handle_info(
        {:bot_reply_delay, bot, bot_message},
        %{assigns: %{game_pid: game_pid}} = socket
      ) do
    {:ok, game_state} = Game.post(game_pid, bot, bot_message)
    {:noreply, assign(socket, :game, game_state)}
  end

  def handle_event(
        "decide",
        %{"decision" => decision},
        %{assigns: %{player_token: player_token, game_pid: game_pid, current_room: current_room}} =
          socket
      ) do
    IO.inspect(decision, label: "game_live_view / handle_event / decide / decision")
    {:ok, game_state} = Game.decide(game_pid, player_token, String.to_atom(decision))
    socket = assign(socket, :game, game_state)
    {:noreply, socket}
  end

  def handle_event(
        "message",
        %{"message" => %{"content" => content, "from" => from}},
        %{assigns: %{player_token: player_token, game_pid: game_pid, current_room: current_room}} =
          socket
      ) do
    {:ok, message} = Message.new(from, content)
    {:ok, game_state} = Game.post(game_pid, player_token, message)
    Phoenix.PubSub.broadcast(@pubsub_name, game_state.registered_name, {:new_message})

    if Game.bot_in_room?(game_state, current_room) do
      send(self(), {:bot_reply, current_room, message})
    end

    {:noreply, assign(socket, :game, game_state)}
  end

  def greet(game, current_room) do
    bot = Game.bot_in_room?(game, current_room)
    ran = :rand.uniform > 0

    if bot && ran do
      {:ok, message} = Message.new(bot, "xxxgreetingxxx")
      IO.inspect(message, label: "game_live_view / greet / message")
      send(self(), {:bot_reply, current_room, message})
    end
  end
end
