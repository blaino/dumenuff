defmodule DumenuffInterfaceWeb.GameLiveView do
  use Phoenix.LiveView

  alias DumenuffEngine.{Game, Decision, Message}

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
         error: nil
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
    socket = assign(socket, :current_room, room)
    {:noreply, socket}
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
        {:bot_reply, room_name, %{from: from} = human_message},
        %{assigns: %{player_token: player_token}} = socket
      )
      when player_token == from do
    {:ok, reply} = NodeJS.call("index", [human_message.content])

    IO.inspect(reply, label: "live / handle_info / :bot_reply / NodeJs / reply")

    charCount = String.length(reply)

    num_players_proxy = 10

    delay = 120 * charCount + (:rand.uniform(3000) * num_players_proxy)
    {:ok, bot_message} = Message.new(human_message.to, human_message.from, reply)

    Process.send_after(self(), {:bot_reply_delay, room_name, bot_message}, delay)

    {:noreply, socket}
  end

  def handle_info({:bot_reply, _room_name, _human_message}, socket) do
    {:noreply, socket}
  end

  def handle_info(
        {:bot_reply_delay, room_name, bot_message},
        %{assigns: %{game_pid: game_pid}} = socket
      ) do
    {:ok, game_state} = Game.post(game_pid, room_name, bot_message)
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
        %{"message" => message_params},
        %{assigns: %{player_token: player_token, game_pid: game_pid, current_room: current_room}} =
          socket
      ) do
    %{"content" => content, "from" => from, "to" => to} = message_params
    {:ok, message} = Message.new(from, to, content)

    {:ok, game_state} = Game.get_state(game_pid)
    room_name = Game.room_by_players(game_state, player_token, current_room)
    {:ok, game_state} = Game.post(game_pid, room_name, message)

    if game_state.players[to].ethnicity == :bot do
      send(self(), {:bot_reply, room_name, message})
    end

    {:noreply, assign(socket, :game, game_state)}
  end
end
