defmodule DumenuffInterfaceWeb.WelcomeController do
  use DumenuffInterfaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  def index(conn, %{}) do
    session =
      get_session(conn)
      # |> Map.put_new("current_user", Pow.Plug.current_user(conn))
      # |> Map.put("_csrf_token", Phoenix.Controller.get_csrf_token())

    live_render(conn, DumenuffInterfaceWeb.GameLiveView, session: session)
  end
end