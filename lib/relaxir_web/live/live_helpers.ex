defmodule RelaxirWeb.LiveHelpers do
  use Phoenix.Component

  @doc """
  Renders a component inside the `RelaxirWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal RelaxirWeb.SearchLive.FormComponent,
        id: @search.id || :new,
        action: @live_action,
        search: @search,
        return_to: Routes.search_index_path(@socket, :index) %>
  """
  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(RelaxirWeb.ModalComponent, modal_opts)
  end
end
