defmodule RelaxirWeb.RecipeLive.FormComponent do
  use RelaxirWeb, :live_component

  alias Relaxir.Recipes
  alias Relaxir.Categories
  alias Relaxir.Ingredients

  import RelaxirWeb.FormattingComponents

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
            allow_clear={true}
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
          <.label>Ingredients</.label>

          <div class="mt-2 mb-4">
            <div class="relative">
              <input
                type="text"
                placeholder="Add ingredient (e.g., '2 cups flour, sifted')"
                class={[
                  "w-full border rounded-lg px-4 py-3 pr-28 focus:ring-2 focus:ring-amber-500 focus:border-amber-500",
                  @show_error && "border-red-500 focus:ring-red-500 focus:border-red-500",
                  !@show_error && "border-neutral-300"
                ]}
                name="ingredient_input"
                id="ingredient_input"
                value={@ingredient_input}
                phx-change="parse_ingredient"
                phx-target={@myself}
                phx-debounce="300"
              />
              <div class="absolute right-0 top-0 bottom-0 flex items-center">
                <%= if @editing_id do %>
                  <button
                    type="button"
                    class="h-full bg-neutral-100 hover:bg-neutral-200 text-neutral-700 font-medium px-4 text-sm transition-colors border-l border-neutral-300"
                    phx-click="cancel_edit"
                    phx-target={@myself}
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    class="h-full bg-green-500 hover:bg-green-600 text-white font-medium px-5 text-sm transition-colors rounded-r-lg"
                    phx-click="add_ingredient"
                    phx-disable-with="Saving..."
                    phx-target={@myself}
                  >
                    Save
                  </button>
                <% else %>
                  <button
                    type="button"
                    class="h-full bg-amber-500 hover:bg-amber-600 text-white font-medium px-5 text-sm transition-colors rounded-r-lg"
                    phx-click="add_ingredient"
                    phx-disable-with="Adding..."
                    phx-target={@myself}
                  >
                    Add
                  </button>
                <% end %>
              </div>
            </div>
            <%= if @show_error && @parsed_ingredient && @parsed_ingredient[:error] do %>
              <div class="mt-2 text-sm text-red-600 font-medium">
                <.icon name="hero-exclamation-circle" class="w-4 h-4 inline-block mr-1" />
                <%= @parsed_ingredient.error %>
              </div>
            <% end %>
          </div>

          <%!-- Added Ingredients List --%>
          <div class="bg-white border border-neutral-300 rounded-lg">
            <%= if @added_ingredients == [] do %>
              <div class="p-6 text-center text-neutral-400 italic">
                No ingredients added yet. Add some using the form above.
              </div>
            <% else %>
              <div class="divide-y divide-neutral-100">
                <%= for {ingredient, index} <- Enum.with_index(@added_ingredients) do %>
                  <div class="p-4 hover:bg-neutral-50">
                    <div class="flex items-start justify-between">
                      <div class="flex-1">
                        <div class="flex items-center justify-between mb-2">
                          <div class="flex items-center gap-2">
                            <div class="text-lg text-black">
                              <span class="inline-flex items-center gap-1">
                                <span class="font-medium text-amber-600">
                                  <%= if ingredient.amount && ingredient.amount != "" do %>
                                    <%= parse_decimal_to_fraction(ingredient.amount) %>
                                  <% end %>
                                </span>
                                <span class="text-neutral-700">
                                  <%= if ingredient.unit && ingredient.unit != "" do %>
                                    <%= " " <> Inflex.pluralize(ingredient.unit) %>
                                  <% end %>
                                </span>
                                <span class="font-medium text-black">
                                  <%= " " <> Inflex.singularize(ingredient.ingredient || "ingredient") %>
                                </span>
                                <%= if ingredient.is_new do %>
                                  <sup class="text-green-500 leading-none" title="This ingredient will be added as new">
                                    <.icon name="hero-plus" class="w-4 h-4 inline-block stroke-2" />
                                  </sup>
                                <% end %>
                                <%= if ingredient.note do %>
                                  <span class="italic text-neutral-500">
                                    <%= ", " <> ingredient.note %>
                                  </span>
                                <% end %>
                              </span>
                            </div>
                          </div>

                          <div class="ml-4">
                            <button
                              type="button"
                              class={[
                                "text-neutral-500 hover:text-neutral-700 p-1 rounded",
                                index == 0 && "opacity-50 cursor-not-allowed"
                              ]}
                              phx-click={if index > 0, do: "move_ingredient_up", else: nil}
                              phx-value-id={ingredient.id}
                              phx-target={@myself}
                              disabled={index == 0}
                              title="Move up"
                            >
                              <.icon name="hero-arrow-up" class="w-4 h-4" />
                            </button>
                          </div>
                        </div>

                        <div class="flex items-center justify-between text-sm">
                          <div class="flex items-center gap-3">
                            <button
                              type="button"
                              class="text-amber-600 hover:text-amber-800 flex items-center gap-1"
                              phx-click="start_edit_ingredient"
                              phx-value-id={ingredient.id}
                              phx-target={@myself}
                            >
                              <.icon name="hero-pencil" class="w-4 h-4" />
                              Update
                            </button>
                            <button
                              type="button"
                              class="text-red-500 hover:text-red-700 flex items-center gap-1"
                              phx-click="remove_ingredient"
                              phx-value-id={ingredient.id}
                              phx-target={@myself}
                            >
                              <.icon name="hero-minus" class="w-4 h-4" />
                              Remove
                            </button>
                          </div>

                          <div>
                            <button
                              type="button"
                              class={[
                                "text-neutral-500 hover:text-neutral-700 p-1 rounded",
                                index == length(@added_ingredients) - 1 && "opacity-50 cursor-not-allowed"
                              ]}
                              phx-click={if index < length(@added_ingredients) - 1, do: "move_ingredient_down", else: nil}
                              phx-value-id={ingredient.id}
                              phx-target={@myself}
                              disabled={index == length(@added_ingredients) - 1}
                              title="Move down"
                            >
                              <.icon name="hero-arrow-down" class="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Hidden field to submit ingredients as pipe-separated strings --%>
        <%= for {ingredient, _idx} <- Enum.with_index(@added_ingredients) do %>
          <input type="hidden" name={"recipe[recipe_ingredients][]"} value={ingredient_to_pipe(ingredient)} />
        <% end %>

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
    added_ingredients =
      if recipe.recipe_ingredients && recipe.recipe_ingredients != [] do
        Enum.map(recipe.recipe_ingredients, fn ri ->
          %{
            id: System.unique_integer([:positive]),
            amount: ri.amount || "",
            unit: if(ri.unit, do: ri.unit.name, else: ""),
            ingredient: ri.ingredient.name,
            note: ri.note || "",
            is_new: false,
            original_input: format_ingredient_input(ri)
          }
        end)
      else
        []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:added_ingredients, added_ingredients)
     |> assign(:ingredient_input, "")
     |> assign(:parsed_ingredient, nil)
     |> assign(:editing_id, nil)
     |> assign(:show_error, false)
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

  @impl true
  def handle_event("parse_ingredient", %{"ingredient_input" => input}, socket) do
    parsed_ingredient = parse_ingredient_input(input)

    socket =
      socket
      |> assign(:ingredient_input, input)
      |> assign(:parsed_ingredient, parsed_ingredient)
      |> assign(:show_error, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_ingredient", _params, socket) do
    input = socket.assigns.ingredient_input

    case parse_ingredient_input(input) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Please enter a valid ingredient")

        {:noreply, socket}

      %{error: error_msg} ->
        socket =
          socket
          |> assign(:show_error, true)
          |> put_flash(:error, error_msg)

        {:noreply, socket}

      parsed_ingredient ->
        case socket.assigns.editing_id do
          nil ->
            new_ingredient = %{
              id: System.unique_integer([:positive]),
              amount: parsed_ingredient.amount,
              unit: parsed_ingredient.unit,
              ingredient: parsed_ingredient.ingredient,
              note: parsed_ingredient.note,
              is_new: parsed_ingredient.is_new,
              original_input: input
            }

            socket =
              socket
              |> assign(:ingredient_input, "")
              |> assign(:parsed_ingredient, nil)
              |> update(:added_ingredients, fn ingredients -> ingredients ++ [new_ingredient] end)

            {:noreply, socket}

          editing_id ->
            socket =
              socket
              |> assign(:ingredient_input, "")
              |> assign(:parsed_ingredient, nil)
              |> assign(:editing_id, nil)
              |> update(:added_ingredients, fn ingredients ->
                Enum.map(ingredients, fn ingredient ->
                  if ingredient.id == editing_id do
                    %{
                      id: ingredient.id,
                      amount: parsed_ingredient.amount,
                      unit: parsed_ingredient.unit,
                      ingredient: parsed_ingredient.ingredient,
                      note: parsed_ingredient.note,
                      is_new: parsed_ingredient.is_new,
                      original_input: input
                    }
                  else
                    ingredient
                  end
                end)
              end)

            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("remove_ingredient", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    socket =
      socket
      |> update(:added_ingredients, fn ingredients ->
        Enum.reject(ingredients, fn ingredient -> ingredient.id == id end)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("start_edit_ingredient", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    ingredient_to_edit = Enum.find(socket.assigns.added_ingredients, fn ingredient -> ingredient.id == id end)

    if ingredient_to_edit do
      reconstructed_input = ingredient_to_edit.original_input || reconstruct_ingredient_input(ingredient_to_edit)

      socket =
        socket
        |> assign(:editing_id, id)
        |> assign(:ingredient_input, reconstructed_input)
        |> assign(:parsed_ingredient, %{
          amount: ingredient_to_edit.amount,
          unit: ingredient_to_edit.unit,
          ingredient: ingredient_to_edit.ingredient,
          note: ingredient_to_edit.note
        })

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    socket =
      socket
      |> assign(:editing_id, nil)
      |> assign(:ingredient_input, "")
      |> assign(:parsed_ingredient, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("move_ingredient_up", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    socket =
      socket
      |> update(:added_ingredients, fn ingredients ->
        move_ingredient_up(ingredients, id)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("move_ingredient_down", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    socket =
      socket
      |> update(:added_ingredients, fn ingredients ->
        move_ingredient_down(ingredients, id)
      end)

    {:noreply, socket}
  end

  # Recipe ingredient input parsing
  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => "recipe_recipe_ingredients"}, socket) do
    case Recipes.parse_ingredient_with_units(text) do
      {:ok, result} ->
        options = Enum.join(result, "|")
        send_update(LiveSelect.Component, id: live_select_id, options: [options])
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => field}, socket) do
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
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp parse_ingredient_input(input) when is_binary(input) and input != "" do
    case Recipes.parse_ingredient_with_units(input) do
      {:ok, [amount, unit, ingredient, note]} ->
        if ingredient == "" or is_nil(ingredient) do
          %{error: "Ingredient is required"}
        else
          is_new = is_nil(Ingredients.get_ingredient_by_name!(ingredient))

          %{
            amount: if(amount != "", do: amount, else: nil),
            unit: if(unit != "", do: unit, else: nil),
            ingredient: ingredient,
            note: if(note != "", do: note, else: nil),
            is_new: is_new
          }
        end
    end
  end

  defp parse_ingredient_input(_), do: nil

  defp reconstruct_ingredient_input(ingredient) do
    parts = []

    parts =
      if ingredient.amount && ingredient.amount != "" do
        [ingredient.amount | parts]
      else
        parts
      end

    parts =
      if ingredient.unit && ingredient.unit != "" do
        [ingredient.unit | parts]
      else
        parts
      end

    parts =
      if ingredient.ingredient && ingredient.ingredient != "" do
        [ingredient.ingredient | parts]
      else
        parts
      end

    parts =
      if ingredient.note && ingredient.note != "" do
        [", " <> ingredient.note | parts]
      else
        parts
      end

    parts |> Enum.reverse() |> Enum.join(" ")
  end

  defp move_ingredient_up(ingredients, id) do
    case Enum.find_index(ingredients, fn ingredient -> ingredient.id == id end) do
      nil -> ingredients
      0 -> ingredients
      index ->
        {before, [prev_ingredient, current_ingredient | rest]} = Enum.split(ingredients, index - 1)
        before ++ [current_ingredient, prev_ingredient] ++ rest
    end
  end

  defp move_ingredient_down(ingredients, id) do
    case Enum.find_index(ingredients, fn ingredient -> ingredient.id == id end) do
      nil -> ingredients
      index when index == length(ingredients) - 1 -> ingredients
      index ->
        {before, [current_ingredient, next_ingredient | rest]} = Enum.split(ingredients, index)
        before ++ [next_ingredient, current_ingredient] ++ rest
    end
  end

  defp ingredient_to_pipe(ingredient) do
    amount = ingredient.amount || ""
    unit = ingredient.unit || ""
    name = ingredient.ingredient || ""
    note = ingredient.note || ""
    Enum.join([amount, unit, name, note], "|")
  end

  defp format_ingredient_input(ri) do
    amount = if ri.amount, do: Float.to_string(ri.amount), else: ""
    unit = if ri.unit, do: ri.unit.name, else: ""
    name = ri.ingredient.name
    note = ri.note || ""

    parts = []
    parts = if amount != "", do: [amount | parts], else: parts
    parts = if unit != "", do: [unit | parts], else: parts
    parts = [name | parts]
    parts = if note != "", do: [", " <> note | parts], else: parts

    Enum.reverse(parts) |> Enum.join(" ")
  end
end
