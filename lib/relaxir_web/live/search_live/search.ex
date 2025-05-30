defmodule RelaxirWeb.SearchLive do
  use RelaxirWeb, :live_view

  alias Relaxir.Search

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    filter =
      if params["f"] do
        String.split(params["f"], ",")
      else
        nil
      end

    {
      :ok,
      socket
      |> assign(:current_user, nil)
      |> assign(:query, params["q"] || "")
      |> assign(:filter, filter)
    }
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"value" => query} = _, socket) do
    {_count, _results} =
      if String.length(query) > 2 do
        get_results(socket.assigns.filter, query)
      else
        {nil, []}
      end

    {
      :noreply,
      socket
      |> push_patch(to: ~p"/search?q=#{query}", replace: true)
    }
  end

  defp apply_action(socket, :search, params) do
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

    socket
    |> assign(:count, count)
    |> assign(:results, results)
    |> assign(:query, params["q"])
  end

  defp get_results(filter, query) do
    sanitized = String.replace(query, "%", "")
    search = Search.search_for("%#{sanitized}%", filter)

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
