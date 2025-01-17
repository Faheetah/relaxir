defmodule RelaxirWeb.CategoryLive.Index do
  use RelaxirWeb, :live_view

  alias Relaxir.Categories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :categories, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    top_categories = Categories.top_categories()

    {
      :noreply,
      assign(socket, :top_categories, top_categories)
    }
  end
end
