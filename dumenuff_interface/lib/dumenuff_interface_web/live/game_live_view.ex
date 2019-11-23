defmodule DumenuffInterfaceWeb.GameLiveView do
  use Phoenix.LiveView

  alias DumenuffEngine.{Game, GameSupervisor, Decision, Message}

  @pubsub_name :dumenuff

  def render(assigns) do
    Phoenix.View.render(DumenuffInterfaceWeb.GameView, "show.html", assigns)
  end

  def mount(session, socket) do
    if connected?(socket), do: join_player(session)

     {:ok, assign(socket,
         game: nil,
         game_pid: nil, # tic tac doesn't have this
         game_name: session.game_name,
         player_token: session.current_player, # was player in tic tac
         current_room: nil,
         message: nil
     )}
  end

  defp join_player(%{game_name: game_name, current_player: current_player}) do
    Phoenix.PubSub.subscribe(@pubsub_name, "dumenuff_updates")

    # tic tac: this is a function call to engine: find_or_create
    {game_pid, game_state} =
      case Enum.at(Supervisor.which_children(GameSupervisor), 0) do
        {_, game_pid, _, _} ->
          {:ok, game_state} = Game.get_state(game_pid)
          {game_pid, game_state}

        nil ->
          {:ok, game_pid} = GameSupervisor.start_game(game_name)
          {:ok, game_state} = Game.get_state(game_pid)
          {game_pid, game_state}
      end

    IO.inspect(game_state, label: "game_state in join_player before add_player")

    # tic tac: error handling on game creation

    # tic tac: no pid
    Phoenix.PubSub.broadcast(@pubsub_name, "dumenuff_updates", {:new_player, game_state, game_pid, current_player})
  end

  def handle_info({:new_player, game, game_pid, current_player}, socket) do

    case Game.add_player(game_pid, current_player, :human) do
      {:ok, game_state} ->
        {:noreply, assign(socket, game: game, game_pid: game_pid, error: nil)}
      {:error, game_state} -> IO.inspect(game_state, "error adding player. game_state: ")
    end
  end

  def handle_info({:tick, game_state}, socket) do
    socket = assign(socket, :game, game_state)
    {:noreply, socket}
  end

  def handle_info(
        {:game_started},
        %{assigns: %{player_token: player_token, game_pid: game_pid}} = socket
      ) do

    IO.inspect(socket, label: "socket in :game_started handler")

    {:ok, game_state} = Game.get_state(game_pid)
    rooms = DumenuffInterfaceWeb.GameView.get_rooms(game_state, player_token)
    socket = assign(socket, :current_room, Enum.at(rooms, 0))
    {:noreply, socket}
  end

  def handle_info(
        {:game_over},
        %{assigns: %{player_token: player_token, game_pid: game_pid}} = socket
      ) do
    {:ok, game_state} = Game.get_state(game_pid)

    {:noreply,
     socket
     |> assign(:game, game_state)
     |> redirect(to: "/scores", replace: true)}
  end

  # when: only send the reply to the right human
  def handle_info(
        {:bot_reply, room_name, %{from: from} = human_message},
        %{assigns: %{player_token: player_token}} = socket
      )
      when player_token == from do
    {:ok, reply} = NodeJS.call("index", [human_message.content])

    charCount = String.length(reply)
    delay = 120 * charCount + :rand.uniform(3000)
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

  # def handle_event(
  #       "add",
  #       %{"params" => %{"name" => name}},
  #       %{assigns: %{game_pid: game_pid}} = socket
  #     ) do
  #   {:ok, game_state} = Game.add_player(game_pid, name, :human)

  #   socket =
  #     socket
  #     |> assign(:game, game_state)
  #     |> assign(:player_token, name)

  #   {:noreply, socket}
  # end

  def handle_event(
        "done",
        _params,
        %{assigns: %{player_token: player_token, game_pid: game_pid}} = socket
      ) do
    {:ok, game_state} = Game.done(game_pid, player_token)

    {:noreply,
     socket
     |> assign(:game, game_state)
     |> redirect(to: "/scores", replace: true)}
  end

  def handle_event("pick", %{"room" => room}, socket) do
    socket = assign(socket, :current_room, room)
    {:noreply, socket}
  end

  def handle_event(
        "decide",
        %{"decision" => decision},
        %{assigns: %{player_token: player_token, game_pid: game_pid, current_room: current_room}} =
          socket
      ) do
    {:ok, decision} = Decision.new(current_room, String.to_existing_atom(decision))
    {:ok, game_state} = Game.decide(game_pid, player_token, decision)
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
