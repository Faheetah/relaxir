defmodule RelaxirWeb.RecipeLive.FormComponent do
  use RelaxirWeb, :live_component

  alias Relaxir.Recipes
  alias Relaxir.Categories

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage recipe records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="recipe-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <.input field={@form[:title]} type="text" label="Title" />

        <.input field={@form[:published]} type="checkbox" label="Published" />

        <.input field={@form[:description]} type="textarea" label="Description" />

        <div>
          <.label for={@form[:categories].id}>Categories</.label>
          <.live_select
            field={@form[:categories]}
            phx-target={@myself}
            mode={:tags}
            dropdown_extra_class="mt-4"
            option_extra_class="py-2"
            container_extra_class="flex flex-col mt-2"
            text_input_extra_class="border-neutral-300 focus:ring-0 focus:border-neutral-400"
            text_input_selected_class="border-neutral-300 focus:ring-0 focus:border-neutral-400"
            tags_container_class="order-last mt-2 p-0 flex flex-wrap gap-1"
            tag_extra_class="bg-neutral-700 text-neutral-100 px-2 py-1"
            style={:tailwind}
          />
        </div>

        <.input field={@form[:directions]} type="textarea" label="Directions" />

        <div>
          <.label for={@form[:categories].id}>
            Ingredients
            <span title={Enum.join(@units, ", ")} class="w-4 h-4">
              <.icon class="w-3 h-3" name="hero-question-mark-circle" />
            </span>
          </.label>
          <.live_select
            field={@form[:recipe_ingredients]}
            phx-target={@myself}
            mode={:tags}
            dropdown_extra_class="mt-4"
            option_extra_class="py-2"
            text_input_extra_class="border-neutral-300 focus:ring-0 focus:border-neutral-400"
            text_input_selected_class="border-neutral-300 focus:ring-0 focus:border-neutral-400"
            container_extra_class="flex flex-col mt-2"
            tags_container_class="order-last mt-2 p-0 flex flex-col flex-wrap gap-1"
            clear_tag_button_extra_class="order-first"
            tag_extra_class="bg-neutral-100 !rounded px-2 py-2"
            style={:tailwind}
          >
            <:option :let={option}>
              <div>
                <.ingredient_option class="text-purple-700" ingredient={option.label} index={0} />
                <.ingredient_option class="text-blue-700" ingredient={option.label} index={1} />
                <.ingredient_option class="text-green-700" ingredient={option.label} index={2} />
                <.ingredient_option class="text-yellow-700" ingredient={option.label} index={3} />
              </div>
            </:option>
            <:tag :let={option}>
              <div>
                <div>
                  <.ingredient_option class="text-purple-700" ingredient={option.label} index={0} />
                  <.ingredient_option class="text-blue-700" ingredient={option.label} index={1} />
                  <.ingredient_option class="text-green-700" ingredient={option.label} index={2} />
                  <.ingredient_option class="text-yellow-700" ingredient={option.label} index={3} />
                </div>
              </div>
            </:tag>
          </.live_select>
        </div>

        <.input field={@form[:note]} type="textarea" label="Note" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Recipe</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{recipe: recipe} = assigns, socket) do
    units =
      Relaxir.Units.list_units
      |> Enum.flat_map(fn u -> [u.name, u.abbreviation] end)
      |> Enum.reject(& &1 == nil)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:units, units)
     |> assign_new(:form, fn ->
       to_form(Recipes.change_recipe(recipe))
     end)}
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    changeset = Recipes.change_recipe(socket.assigns.recipe, recipe_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    save_recipe(socket, socket.assigns.action, recipe_params)
  end

  # Temporary POC for ingredients submissions
  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => "recipe_recipe_ingredients"}, socket) do
    # parse this and return it back
    # options = ["1|cup|some ingredient|stupid", "2|cup|beef bar|note"]
    {:ok, result} = Recipes.parse_ingredient(text, socket.assigns.units)
    options = Enum.join(result, "|")
    send_update(LiveSelect.Component, id: live_select_id, options: [options])

    {:noreply, socket}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => field}, socket) do
    IO.inspect live_select_id
    items =
      case field do
        "recipe_categories" -> Categories.search_categories(text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: [text | items], placeholder: "")

    {:noreply, socket}
  end

  defp save_recipe(socket, :edit, recipe_params) do
    case Recipes.update_recipe(socket.assigns.recipe, recipe_params) do
      {:ok, recipe} ->
        notify_parent({:saved, recipe})

        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")
         |> push_navigate(to: ~p"/recipes/#{recipe.id}")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, assign(socket, form: to_form(Recipes.change_recipe(socket.assigns.recipe, recipe_params)))}
    end
  end

  defp save_recipe(socket, :new, recipe_params) do
    case Recipes.create_recipe(recipe_params) do
      {:ok, recipe} ->
        notify_parent({:saved, recipe})

        {:noreply,
         socket
         |> put_flash(:info, "Recipe created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
