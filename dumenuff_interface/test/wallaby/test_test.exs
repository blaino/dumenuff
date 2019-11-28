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

  test "Add two players and start the game", %{session: session} do
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

    {:ok, player3} = Wallaby.start_session()

    player3
    |> visit("/")
    |> fill_in(css("#player_name"), with: "player3")
    |> click(button("Enter"))
    |> assert_has(css(".waiting", text: "Waiting"))

    {:ok, player4} = Wallaby.start_session()

    player4
    |> visit("/")
    |> fill_in(css("#player_name"), with: "player4")
    |> click(button("Enter"))

    player3
    |> assert_has(button("DONE"))

    player4
    |> assert_has(button("DONE"))
    |> take_screenshot

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
