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

  test "blah", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css("#params_name"))
  end
end
