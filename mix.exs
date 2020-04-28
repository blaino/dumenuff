defmodule Mix.Tasks.UmbrellaNpmInstall do
  use Mix.Task
  require Logger

  def run(_) do
    # Mix.shell().info("(Umbrella) Running npm install to get rivescript and its dependencies")
    # Mix.shell().cmd("cd apps/dumenuff_bots && npm install")
    Logger.info "(Umbrella) Running npm install to get rivescript and its dependencies"
    System.cmd("npm", ["install"], cd: "apps/dumenuff_bots/priv/node")
    Logger.info "npm install complete"
  end
end


defmodule DumenuffUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      default_task: "UmbrellaNpmInstall",
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end
