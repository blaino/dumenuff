defmodule DumenuffInterfaceWeb.LobbyController do
  use DumenuffInterfaceWeb, :controller

  alias DumenuffEngine.GameSupervisor

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"player" => player_params}) do
    IO.inspect(player_params, label: "lobby_controller / create / player_params")
    player_name = Map.get(player_params, "player_name", "Anonymous")

    conn =
      conn
      |> set_player_name(player_name)
      |> set_game
      # |> IO.inspect(label: "lobby_controller / create / conn")

    IO.inspect(get_session(conn), label: "lobby_controller / create / get_session(conn)")

    game_name = get_session(conn, :game_name)

    conn
    |> redirect(to: Routes.game_path(conn, :show, game_name))
  end

  defp set_player_name(conn, player_name) do
    conn
    |> assign(:player_name, player_name)
    |> put_session(:player_name, player_name)
    |> configure_session(renew: true)
  end

  defp set_game(conn) do
    {game_pid, game_name} = GameSupervisor.find_or_create_game()

    conn
    |> assign(:game_pid, game_pid)
    |> put_session(:game_pid, game_pid)
    |> assign(:game_name, game_name)
    |> put_session(:game_name, game_name)
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: Routes.lobby_path(conn, :new))
  end
end
