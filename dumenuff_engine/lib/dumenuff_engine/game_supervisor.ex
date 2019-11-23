defmodule DumenuffEngine.GameSupervisor do
  use Supervisor

  alias DumenuffEngine.Game

  def start_link(_options) do
    IO.puts("game_supervisor / start_link")
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: Supervisor.init([Game], strategy: :simple_one_for_one)

  def start_game(name) do
    IO.puts("game_supervisor / start_game")
    Supervisor.start_child(__MODULE__, [name])
  end

  def stop_game(name) do
    :ets.delete(:game_state, name)
    Supervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
