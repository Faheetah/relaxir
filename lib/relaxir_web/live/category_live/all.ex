defmodule RelaxirWeb.CategoryLive.All do
  use RelaxirWeb, :live_view

  alias Relaxir.Categories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :categories, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    categories = Categories.list_categories()

    {
      :noreply,
      assign(socket, :categories, categories)
    }
  end
end
