defmodule DumenuffInterfaceWeb.ScoresController do
  use DumenuffInterfaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  def show(conn, %{"name" => name}) do
    IO.inspect(name, label: "scores / controller / show / name: ")
    IO.inspect(conn.assigns.current_player, label: "scores / controller / show / current_player: ")
    session = %{game_name: name,
                current_player: conn.assigns.current_player,
                game_pid: conn.assigns.game_pid}

    session = get_session(conn)
    live_render(conn, DumenuffInterfaceWeb.ScoresLiveView, session: session)
  end
end
