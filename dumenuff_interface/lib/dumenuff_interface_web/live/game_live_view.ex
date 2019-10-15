defmodule DumenuffInterfaceWeb.GameLiveView do
  use Phoenix.LiveView

  alias DumenuffEngine.{Game, GameSupervisor, Decision}

  def render(assigns) do
    Phoenix.View.render(DumenuffInterfaceWeb.GameView, "index.html", assigns)
  end

  def mount(_session, socket) do
    {game_pid, game_state} =
      case Enum.at(Supervisor.which_children(GameSupervisor), 0) do
        {_, game_pid, _, _} ->
          {:ok, game_state} = Game.get_state(game_pid)
          {game_pid, game_state}
        nil ->
          {:ok, game_pid} = GameSupervisor.start_game("PlaceholderGame")
          {:ok, game_state} = Game.get_state(game_pid)
          {game_pid, game_state}
      end

    socket =
      socket
      |> assign(:game, game_state)
      |> assign(:game_pid, game_pid)
      |> assign(:player_token, nil)

    Phoenix.PubSub.subscribe(:dumenuff, "dumenuff_updates")

    {:ok, socket}
  end

  def handle_info({:tick, game_state}, socket) do
    # IO.inspect(game_state, label: "============================= handle info")
    socket = assign(socket, :game, game_state)

    # IO.inspect(socket.assigns.player_token, label: "======================== socket.assigns")
    {:noreply, socket}
  end

  def handle_event("add",
    %{"params" => %{"name" => name}},
    %{assigns: %{game_pid: game_pid}} = socket) do

    {:ok, game_state} = Game.add_player(game_pid, name, :human)

    socket =
      socket
      |> assign(:game, game_state)
      |> assign(:player_token, name)

    {:noreply, socket}
  end

  def handle_event("done",
    _params,
    %{assigns: %{player_token: player_token, game_pid: game_pid}} = socket) do

    {:ok, game_state} = Game.done(game_pid, player_token)

    socket = assign(socket, :game, game_state)

    {:noreply, socket}
  end

  def handle_event("pick", %{"room" => room}, socket) do
    socket = assign(socket, :current_room, room)
    {:noreply, socket}
  end

  def handle_event("decide",
    %{"decision" => decision},
    %{assigns: %{player_token: player_token, game_pid: game_pid, current_room: current_room}} = socket) do

    {:ok, decision} = Decision.new(current_room, String.to_existing_atom(decision))
    {:ok, game_state} = Game.decide(game_pid, player_token, decision)
    socket = assign(socket, :game, game_state)
    {:noreply, socket}
  end


end
