defmodule DumenuffInterfaceWeb.ScoresLiveView do
  use Phoenix.LiveView

  alias DumenuffEngine.{Game, GameSupervisor}

  def render(assigns) do
    Phoenix.View.render(DumenuffInterfaceWeb.ScoresView, "index.html", assigns)
  end

  def mount(_session, socket) do
    {game_pid, game_state} =
      case Enum.at(Supervisor.which_children(GameSupervisor), 0) do
        {_, game_pid, _, _} ->
          {:ok, game_state} = Game.get_state(game_pid)
          {game_pid, game_state}

        nil ->
          :error
      end

    socket =
      socket
      |> assign(:game, game_state)
      |> assign(:game_pid, game_pid)

    {:ok, socket}
  end
end
