defmodule DumenuffInterfaceWeb.LobbyController do
  use DumenuffInterfaceWeb, :controller

  def index(conn, %{}) do
    session = get_session(conn)
    live_render(conn, DumenuffInterfaceWeb.LobbyLiveView, session: session)
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"player" => player_params}) do
    player = Map.get(player_params, "name", "Anonymous")
    conn
    |> set_player(player)
    |> redirect(to: Routes.game_path(conn, :new))
  end

  defp set_player(conn, player) do
    conn
    |> assign(:current_player, player)
    |> put_session(:current_player, player)
    |> configure_session(renew: true)
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: Routes.lobby_path(conn, :new))
  end
end
