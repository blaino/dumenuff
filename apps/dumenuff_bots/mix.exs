# defmodule Mix.Tasks.NpmInstall do
#   use Mix.Task

#   def run(_) do
#     Mix.shell().info("Running npm install to get rivescript and its dependencies")
#     Mix.shell().cmd("npm install")
#   end
# end

defmodule DumenuffBots.MixProject do
  use Mix.Project

  def project do
    [
      app: :dumenuff_bots,
      # default_task: "NpmInstall",
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      # deps: deps(),
      # Umbrella
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      lockfile: "../../mix.lock",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

end
