defmodule DumenuffInterfaceWeb.ScoresLiveView do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(DumenuffInterfaceWeb.ScoresView, "show.html", assigns)
  end

  def mount(
    %{game_state: game_state},
    socket) do

    IO.inspect(game_state.registered_name, label: "scores / live / mount / game_state.registered_name: ")

    if connected?(socket) do
      IO.puts "scores / live / mount / connected"

      Phoenix.PubSub.subscribe(:dumenuff, game_state.registered_name)
      # {:ok, game_state} = Game.get_state(game_pid)

      {:ok, assign(socket, game: game_state)}
    else
      {:ok, assign(socket, game: nil)}
    end
  end

  def handle_info({:tick, game_state}, socket) do
    socket = assign(socket, :game, game_state)
    {:noreply, socket}
  end

  def handle_info({:game_over}, socket) do
    {:noreply, socket}
  end

  def handle_event("new_game", _, socket) do
    {:noreply,
     socket
    |> redirect(to: DumenuffInterfaceWeb.Router.Helpers.lobby_path(DumenuffInterfaceWeb.Endpoint, :new))}
  end

end
