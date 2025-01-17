defmodule RelaxirWeb.RecipeLive.RecipeCardComponent do
  use RelaxirWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
