use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dumenuff_interface, DumenuffInterfaceWeb.Endpoint,
  http: [port: 4000],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :wallaby, screenshot_on_failure: true

config :wallaby,
  driver: Wallaby.Experimental.Chrome

config :wallaby,
  chrome: [
    headless: true
  ]

config :wallaby,
  hackney_options: [timeout: :infinity, recv_timeout: :infinity]
