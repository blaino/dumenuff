defmodule DumenuffInterfaceWeb.Plugs.Lobby do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _options) do
    IO.puts "plugs / lobby / call"
    conn
    |> assign_player_name
    |> assign_game_pid
    |> assign_game_name
  end

  defp assign_player_name(conn) do
    cond do
      player = conn.assigns[:player_name] ->
        assign(conn, :player_name, player)

      player = get_session(conn, :player_name) ->
        assign(conn, :player_name, player)

      true ->
        assign(conn, :player_name, nil)
    end
  end

  defp assign_game_pid(conn) do
    cond do
      player = conn.assigns[:game_pid] ->
        assign(conn, :game_pid, player)

      player = get_session(conn, :game_pid) ->
        assign(conn, :game_pid, player)

      true ->
        assign(conn, :game_pid, nil)
    end
  end

  defp assign_game_name(conn) do
    cond do
      player = conn.assigns[:game_name] ->
        assign(conn, :game_name, player)

      player = get_session(conn, :game_name) ->
        assign(conn, :game_name, player)

      true ->
        assign(conn, :game_name, nil)
    end
  end

end
