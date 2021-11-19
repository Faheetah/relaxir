defmodule RelaxirWeb.SearchLive.Search do
  use RelaxirWeb, :live_view

  alias Relaxir.Search

  @impl true
  def mount(params, _session, socket) do
    fields =
      params
      |> Map.get("f", "recipes,categories,ingredients,usda")
      |> String.split(",")

    {count, results} = get_results(fields, params["q"])

    {
      :ok,
      socket
      |> assign(:count, count)
      |> assign(:results, results)
      |> assign(:query, %{})
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :search, _params) do
    socket
    |> assign(:page_title, "Listing Searches")
  end

  defp get_results(fields, query) do
    search = Search.search_for(fields, query)

    count = Enum.reduce(search, 0, fn {_, i}, acc -> acc + length(i) end)

    results =
      search
      |> Enum.map(fn {category, values} ->
        {
          String.capitalize(category),
          values
          |> Stream.map(fn {[value, id], _} -> %{id: id, value: value} end)
          |> Enum.take(20)
        }
      end)

    {count, results}
  end
end
