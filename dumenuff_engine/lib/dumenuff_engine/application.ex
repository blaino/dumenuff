defmodule DumenuffEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: DumenuffEngine.Worker.start_link(arg)
      # {DumenuffEngine.Worker, arg}
      {Registry, keys: :unique, name: Registry.Game}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DumenuffEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
