defmodule RelaxirWeb.ToolLive.Show do
  use RelaxirWeb, :live_view

  @impl true
  def mount(%{"name" => name}, _session, socket) do
    {
      :ok,
      assign(socket, :tool, name)
    }
  end
end
