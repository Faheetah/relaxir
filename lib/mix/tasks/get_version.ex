defmodule Mix.Tasks.GetVersion do
  use Mix.Task

  @shortdoc "Get the version for a release"
  def run(_) do
    project = Relaxir.MixProject.project()
    IO.write(project[:version])
  end
end
