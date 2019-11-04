defmodule DumenuffInterfaceWeb.ScoresController do
  use DumenuffInterfaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  def index(conn, %{}) do
    session = get_session(conn)
    live_render(conn, DumenuffInterfaceWeb.ScoresLiveView, session: session)
  end
end
