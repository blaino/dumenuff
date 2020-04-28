defmodule DumenuffInterfaceWeb.Plugs.Lobby do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _options) do
    IO.puts "plugs / lobby / call"
    conn
    |> assign_current_player
    |> assign_real_name
    |> assign_game_pid
    |> assign_game_name
  end

  defp assign_current_player(conn) do
    cond do
      player = conn.assigns[:current_player] ->
        assign(conn, :current_player, player)

      player = get_session(conn, :current_player) ->
        assign(conn, :current_player, player)

      true ->
        assign(conn, :current_player, nil)
    end
  end

  defp assign_real_name(conn) do
    cond do
      player = conn.assigns[:real_name] ->
        assign(conn, :real_name, player)

      player = get_session(conn, :real_name) ->
        assign(conn, :real_name, player)

      true ->
        assign(conn, :real_name, nil)
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
