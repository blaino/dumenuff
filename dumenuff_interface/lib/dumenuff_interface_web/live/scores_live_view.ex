defmodule DumenuffInterfaceWeb.ScoresLiveView do
  use Phoenix.LiveView

  alias DumenuffEngine.{Game, GameSupervisor}

  def render(assigns) do
    Phoenix.View.render(DumenuffInterfaceWeb.ScoresView, "show.html", assigns)
  end

  def mount(
    %{"game_name" => game_name, "game_pid" => game_pid, "current_player" => current_player},
    socket) do

    IO.inspect(game_name, label: "scores / live / mount / game_name: ")

    if connected?(socket) do
      IO.puts "scores / live / mount / connected"

      Phoenix.PubSub.subscribe(:dumenuff, game_name)
      {:ok, game_state} = Game.get_state(game_pid)

      {:ok, assign(socket,
          game: game_state,
          game_pid: game_pid,
          game_name: game_name,
          player_token: current_player,
        )}
    else
      {:ok, assign(socket,
          game: nil,
          game_pid: nil,
          game_name: nil,
          player_token: nil,
        )}
    end
  end

  def handle_info({:tick, game_state}, socket) do
    IO.inspect(game_state.registered_name, label: "scores / live / handle_info / :tick / registered_name")
    socket = assign(socket, :game, game_state)
    {:noreply, socket}
  end

  def handle_info({:game_over}, socket) do
    {:noreply, socket}
  end

end
