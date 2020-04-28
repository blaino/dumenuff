ExUnit.start(exclude: [:skip])

{:ok, _} = Application.ensure_all_started(:wallaby)

# Application.put_env(:wallaby, :base_url, DumenuffInterfaceWeb.Endpoint.url)
Application.put_env(:wallaby, :base_url, "http://localhost:4000")
