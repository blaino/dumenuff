defmodule DumenuffInterfaceWeb.Router do
  use DumenuffInterfaceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    # plug :put_layout, {DumenuffInterfaceWeb.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DumenuffInterfaceWeb do
    pipe_through :browser

    get "/", WelcomeController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", DumenuffInterfaceWeb do
  #   pipe_through :api
  # end
end
