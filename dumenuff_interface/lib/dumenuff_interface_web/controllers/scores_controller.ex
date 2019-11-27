defmodule DumenuffInterfaceWeb.ScoresController do
  use DumenuffInterfaceWeb, :controller

  alias DumenuffEngine.Game

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  def show(conn, %{"name" => name}) do
    IO.inspect(name, label: "scores / controller / show / name: ")
    IO.inspect(conn.assigns.current_player, label: "scores / controller / show / current_player: ")

    game_pid = Game.pid_from_name(name)
    {:ok, game_state} = Game.get_state(game_pid)

    session = %{game_state: game_state}

    live_render(conn, DumenuffInterfaceWeb.ScoresLiveView, session: session)
  end
end
