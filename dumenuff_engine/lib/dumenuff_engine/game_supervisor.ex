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
    Supervisor.terminate_child(__MODULE__, Game.pid_from_name(name))
  end

  @doc """

  """
  def find_or_create_game() do
    # case Enum.at(Supervisor.which_children(__MODULE__), 0) do
    case available_game() do
      {_, game_pid, _, _} ->
        IO.inspect(game_pid, label: "game_supervisor / found game: ")
        {:ok, game_state} = Game.get_state(game_pid)
        {game_pid, game_state.registered_name}
      nil ->
        game_name = UUID.uuid1(:hex)
        {:ok, game_pid} = __MODULE__.start_game(game_name)
        IO.inspect(game_pid, label: "game_supervisor / created game: ")
        {game_pid, game_name}
    end
  end

  @doc """
  Returns available game. If none available return nil
  """
  def available_game() do
    Enum.find(Supervisor.which_children(__MODULE__), fn {_, pid, _, _} ->
      {:ok, game_state} = Game.get_state(pid)
      game_state.rules.state == :initialized
    end)
  end

  @doc """
  Returns index available game. If none available return nil
  """
  def available_game_index() do
    Enum.find_index(Supervisor.which_children(__MODULE__), fn {_, pid, _, _} ->
      {:ok, game_state} = Game.get_state(pid)
      game_state.rules.state == :initialized
    end)
  end

  @doc """
  Checks if there is a  process running with the given name.
  """
  def game_exists?(game_name) do
    case Registry.lookup(Registry.Game, game_name) do
      [] -> false
      _ -> true
    end
  end
end
