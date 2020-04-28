defmodule DumenuffInterfaceWeb.PageControllerTest do
  use DumenuffInterfaceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "D U M E N U F F"
  end
end
