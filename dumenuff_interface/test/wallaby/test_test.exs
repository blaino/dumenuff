defmodule DumenuffInterface.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
      # import DumenuffInterface.Router.Helpers
    end
  end

  # setup tags do
  #   {:ok, session} = Wallaby.start_session()
  #   {:ok, session: session}
  # end
end

defmodule DumenuffInterface.UserListTest do
  use DumenuffInterface.FeatureCase, async: true

  import Wallaby.Query

  # returns a list of session, player_name pairs
  defp start_sessions(num_sessions) do
    Enum.map(1..num_sessions, fn index ->
      {:ok, session} = Wallaby.start_session()
      # [session: session, name: "player"<>index]
      {session, "player"<>Integer.to_string(index)}
    end)
  end

  # N has to be a multiple of players_to_start
  test "Add N players start through scores" do
    sessions = start_sessions(20)
    Enum.each(sessions, fn {session, player} ->
      session
      |> visit("/")
      |> fill_in(css("#player_name"), with: player)
      |> click(button("Enter"))
    end)

    Enum.each(sessions, fn {session, _player} ->
      session
      |> assert_has(button("DONE"))
    end)

    Enum.each(sessions, fn {session, player} ->
      session
      |> click(button("DONE"))
      |> assert_has(css(".score-score", count: 4, text: "bonus"))
      |> assert_has(css(".score-score", count: 3, text: player))
    end)
  end

  # @tag :skip
  test "Add 2 players, start the game, check waiting, scores" do
    {:ok, player1} = Wallaby.start_session()

    player1
    |> visit("/")
    |> fill_in(css("#player_name"), with: "player1")
    |> click(button("Enter"))
    |> assert_has(css(".waiting", text: "Waiting"))

    {:ok, player2} = Wallaby.start_session()

    player2
    |> visit("/")
    |> fill_in(css("#player_name"), with: "player2")
    |> click(button("Enter"))

    player1
    |> assert_has(button("DONE"))

    player2
    |> assert_has(button("DONE"))

    player1
    |> click(button("DONE"))
    |> assert_has(css(".waiting", text: "This game"))
    |> assert_has(css(".score-score", count: 3, text: "player1"))

    player2
    |> click(button("DONE"))
    |> assert_has(css(".score-score", count: 4, text: "bonus"))
    |> assert_has(css(".score-score", count: 3, text: "player2"))

  end
end
