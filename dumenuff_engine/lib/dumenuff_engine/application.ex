defmodule DumenuffEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Game},
      DumenuffEngine.GameSupervisor,
      %{
        id: Phoenix.PubSub.PG2,
        start: {Phoenix.PubSub.PG2, :start_link, [:dumenuff, []]}
      }
    ]

    :ets.new(:game_state, [:public, :named_table])
    opts = [strategy: :one_for_one, name: DumenuffEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
