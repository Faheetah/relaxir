defmodule RelaxirWeb.CategoryLive.FormComponent do
  use RelaxirWeb, :live_component

  alias Relaxir.Categories

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @name %>
        <:subtitle>Use this form to manage category records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="category-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <.input field={@form[:name]} type="text" label="Name" />

        <.input field={@form[:image_filename]} type="text" label="Image Filename" />

        <.link
          class="flex bg-neutral-900 text-white text-4xl"
          navigate={~p"/images/#{@category}/upload?#{%{redirect: "/categories/#{@category.id}/upload", path: @category.image_filename || ""}}"}
        >
          <span class="place-self-center text-center w-full">Upload an image</span>
        </.link>

        <:actions>
          <.button phx-disable-with="Saving...">Save Category</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{category: category} = assigns, socket) do
    units =
      Relaxir.Units.list_units
      |> Enum.flat_map(fn u -> [u.name, u.abbreviation] end)
      |> Enum.reject(& &1 == nil)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:units, units)
     |> assign_new(:form, fn ->
       to_form(Categories.change_category(category))
     end)}
  end

  @impl true
  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset = Categories.change_category(socket.assigns.category, category_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.action, category_params)
  end

  defp save_category(socket, :edit, category_params) do
    case Categories.update_category(socket.assigns.category, category_params) do
      {:ok, category} ->
        notify_parent({:saved, category})

        {:noreply,
         socket
         |> put_flash(:info, "Category updated successfully")
         |> push_navigate(to: ~p"/categories/#{category.name}")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, assign(socket, form: to_form(Categories.change_category(socket.assigns.category, category_params)))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
