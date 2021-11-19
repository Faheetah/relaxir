defmodule RelaxirWeb.SearchLive.Search do
  use RelaxirWeb, :live_view

  alias Relaxir.Search

  @impl true
  def mount(params, _session, socket) do
    filter =
      if params["f"] do
        String.split(params["f"], ",")
      else
        nil
      end

    {count, results} =
      if params["q"] do
        get_results(filter, params["q"])
      else
        {nil, []}
      end

    {
      :ok,
      socket
      |> assign(:count, count)
      |> assign(:results, results)
      |> assign(:query, params["q"] || "")
      |> assign(:filter, filter)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("search", %{"value" => query} = _, socket) do
    {count, results} =
      if String.length(query) > 3 do
        get_results(socket.assigns.filter, query)
      else
        {nil, []}
      end

    {
      :noreply,
      socket
      |> assign(:count, count)
      |> assign(:results, results)
      |> assign(:query, query)
    }
  end

  defp apply_action(socket, :search, _params) do
    socket
    |> assign(:page_title, "Listing Searches")
  end

  defp get_results(filter, query) do
    search = Search.search_for(filter, query)

    count = Enum.reduce(search, 0, fn {_, i}, acc -> acc + length(i) end)

    results =
      search
      |> Enum.map(fn {category, values} ->
        {
          category,
          values
          |> Stream.map(fn {[value, id], _} -> %{id: id, value: value} end)
          |> Enum.take(20)
        }
      end)

    {count, results}
  end
end
