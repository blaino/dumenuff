defmodule DumenuffInterface.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
      # import DumenuffInterface.Router.Helpers
    end
  end

  setup tags do
    {:ok, session} = Wallaby.start_session()
    {:ok, session: session}
  end
end

defmodule DumenuffInterface.UserListTest do
  use DumenuffInterface.FeatureCase, async: true

  import Wallaby.Query

  test "truth" do
    assert true
  end

  # try 3 players and assume 2 person game
  test "Add two players and start the game", %{session: session} do
    {:ok, player1} = Wallaby.start_session()

    player1
    |> visit("/")
    |> fill_in(css("#params_name"), with: "alice")
    |> click(button("Add"))

    {:ok, player2} = Wallaby.start_session()

    player2
    |> visit("/")
    |> fill_in(css("#params_name"), with: "bob")
    |> click(button("Add"))

    player1
    |> assert_has(button("DONE"))

    player2
    |> assert_has(button("DONE"))

    {:ok, player3} = Wallaby.start_session()

    player3
    |> visit("/")
    |> fill_in(css("#params_name"), with: "mike")
    |> click(button("Add"))

    {:ok, player4} = Wallaby.start_session()

    player4
    |> visit("/")
    |> fill_in(css("#params_name"), with: "zrobert")
    |> click(button("Add"))

    player3
    |> assert_has(button("DONE"))

    player4
    |> assert_has(button("DONE"))
    |> take_screenshot
  end
end
