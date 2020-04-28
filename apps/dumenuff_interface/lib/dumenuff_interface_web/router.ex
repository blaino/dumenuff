defmodule DumenuffInterfaceWeb.Router do
  use DumenuffInterfaceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_flash
    plug DumenuffInterfaceWeb.Plugs.Lobby
    plug Phoenix.LiveView.Flash
    # plug :put_layout, {DumenuffInterfaceWeb.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DumenuffInterfaceWeb do
    pipe_through :browser

    get "/", LobbyController, :new
    resources "/lobby", LobbyController, only: [:new, :create, :delete]

    resources "/game", GameController, only: [:new, :create, :show], param: "name"

    resources "/scores", ScoresController, only: [:show], param: "name"
  end

end
