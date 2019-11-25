defmodule DumenuffInterfaceWeb.GameController do
  use DumenuffInterfaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  def show(conn, %{"name" => name}) do
    IO.inspect(name, label: "game_controller / show / name: ")
    session = %{game_name: name,
                current_player: conn.assigns.current_player,
                game_pid: conn.assigns.game_pid}
    live_render(conn, DumenuffInterfaceWeb.GameLiveView, session: session)
  end

  defp check_player(conn, _options) do
    if conn.assigns.current_player do
      conn
    else
      conn
      |> put_flash(:error, "You must configure a player to get into a game")
      |> redirect(to: Routes.lobby_path(conn, :new))
      |> halt()
    end
  end
end
