defmodule DumenuffInterfaceWeb.GameController do
  use DumenuffInterfaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  def show(conn, %{"name" => name}) do
    IO.inspect(name, label: "game_controller / show / name: ")
    session = %{game_name: name,
                current_player: conn.assigns.current_player,
                real_name: conn.assigns.real_name,
                game_pid: conn.assigns.game_pid}
    live_render(conn, DumenuffInterfaceWeb.GameLiveView, session: session)
  end
end
