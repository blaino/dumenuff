defmodule DumenuffInterfaceWeb.GameController do
  use DumenuffInterfaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"game" => game_params}) do
    case Map.get(game_params, "name") do
      nil ->
        conn
        |> put_flash(:error, "Game cannot be empty")
        |> render("new.html")

      name ->
        redirect(conn, to: Routes.game_path(conn, :show, name))
    end
  end

  def show(conn, %{"name" => name}) do
    session = %{game_name: name, current_player: conn.assigns.current_player}
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
