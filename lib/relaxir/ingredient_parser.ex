defmodule Relaxir.IngredientParser do
  alias Relaxir.Ingredients
  alias Relaxir.Units

  def map_existing_ingredients(attrs, recipe) do
    current_recipe_ingredients =
      recipe.recipe_ingredients
      |> Enum.reduce(
        [],
        fn ri, acc ->
          [%{id: ri.id, ingredient: %{id: ri.ingredient.id}} | acc]
        end
      )

    recipe_ingredients =
      (attrs["recipe_ingredients"] || [])
      |> Enum.map(fn i ->
        case i do
          %{:ingredient_id => id} ->
            Enum.find(
              current_recipe_ingredients,
              %{recipe_id: recipe.id, ingredient_id: id},
              fn cri ->
                if cri.ingredient.id == id do
                  cri
                end
              end
            )
            |> Map.merge(%{
              note: Map.get(i, :note),
              amount: Map.get(i, :amount),
              unit_id: Map.get(i, :unit_id)
            })

          _ ->
            i
        end
      end)

    errors =
      Enum.find(
        recipe_ingredients,
        fn i ->
          case i do
            {:error, error} -> error
            _ -> nil
          end
        end
      )

    if errors != nil do
      Map.put(attrs, "errors", errors)
    else
      Map.put(attrs, "recipe_ingredients", recipe_ingredients)
    end
  end

  def map_ingredients(attrs) when is_map_key(attrs, "ingredients") do
    units = Units.list_units()

    ingredients =
      attrs["ingredients"]
      |> Enum.map(&map_recipe_ingredient_fields(&1, units))

    fetched_ingredients =
      ingredients
      |> Enum.map(fn i -> i.name end)
      |> Ingredients.get_ingredients_by_name!()

    ingredients =
      ingredients
      |> Enum.map(&match_existing_ingredients(&1, fetched_ingredients))

    Map.put(attrs, "recipe_ingredients", ingredients)
  end

  def map_ingredients(attrs), do: attrs

  defp match_existing_ingredients(ingredient, fetched_ingredients) do
    case Enum.find(fetched_ingredients, fn i -> i.name == ingredient.name end) do
      nil -> %{ingredient: ingredient}
      ingredient -> %{ingredient_id: ingredient.id}
    end
    |> Map.merge(ingredient)
    |> Map.delete(:name)
  end

  def map_recipe_ingredient_fields(attrs, units) do
    amount = Map.get(attrs, :amount)
    unit_name = Map.get(attrs, :unit)

    cond do
      amount == nil || unit_name == nil -> attrs
      amount > 1 -> {:ok, Enum.find(units, fn u -> Inflex.singularize(unit_name) == u.name end)}
      true -> {:ok, Enum.find(units, fn u -> unit_name == u.name end)}
    end
    |> case do
      {:ok, nil} ->
        cond do
          Map.get(attrs, :name) ->
            attrs
            |> Map.merge(%{
              name:
                [unit_name, attrs.name]
                |> Enum.join(" ")
                |> String.trim(),
              amount: amount
            })
            |> Map.delete(:unit)

          true ->
            Map.merge(attrs, %{amount: amount})
        end

      {:ok, unit} ->
        attrs
        |> Map.merge(%{
          amount: amount,
          unit_id: unit.id
        })

      {:error, error} ->
        {:error, error}

      attrs ->
        attrs
    end
  end
end
