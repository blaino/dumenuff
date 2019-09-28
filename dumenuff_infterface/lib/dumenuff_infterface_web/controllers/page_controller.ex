defmodule DumenuffInfterfaceWeb.PageController do
  use DumenuffInfterfaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
