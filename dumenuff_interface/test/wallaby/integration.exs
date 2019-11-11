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
    {:ok, player1} = Wallaby.start_session
    player1
    |> visit("/")
    |> fill_in(css("#params_name"), with: "alice")
    |> click(button("Add"))

    {:ok, player2} = Wallaby.start_session
    player2
    |> visit("/")
    |> fill_in(css("#params_name"), with: "bob")
    |> click(button("Add"))

    player1
    |> assert_has(button("DONE"))

    player2
    |> assert_has(button("DONE"))
  end
end
