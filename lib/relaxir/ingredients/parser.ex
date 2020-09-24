defmodule Relaxir.Ingredients.Parser do
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
      true -> {:ok, Enum.find(units, fn u -> Inflex.singularize(unit_name) == u.name end)}
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

  def parse_ingredients(attrs) do
    ingredients =
      attrs["ingredients"]
      |> Enum.map(&extract_ingredient_fields/1)
      |> Enum.map(fn ingredient ->
        case ingredient do
          {:ok, ingredient} -> ingredient
          {:error, error} -> {:error, error}
          [] -> []
        end
      end)

    Map.put(attrs, "ingredients", ingredients)
  end

  def extract_ingredient_fields(ingredient) do
    {:ok, %{name: ingredient}}
    |> extract_ingredient_note
    |> extract_ingredient_amount
  end

  def extract_ingredient_amount({:ok, ingredient}) do
    case String.split(ingredient.name) do
      [whole, fraction, unit | name] ->
        cond do
          Float.parse(fraction) != :error and Float.parse(whole) != :error and hd(Tuple.to_list(Float.parse(fraction))) ->
            parsed_amount = hd(Tuple.to_list(Float.parse(whole))) + parse_amount(fraction)
            build_ingredient(parsed_amount, ingredient: ingredient, unit: unit, name: name)

          true ->
            build_ingredient(parse_amount(whole), ingredient: ingredient, unit: fraction, name: [unit | name])
        end

      [amount, unit | name] ->
        build_ingredient(parse_amount(amount), ingredient: ingredient, unit: unit, name: name)

      _ ->
        {:ok, ingredient}
    end
  end

  defp build_ingredient(:error, ingredient: ingredient, unit: _unit, name: _name) do
    {:ok, ingredient}
  end

  defp build_ingredient(amount, ingredient: ingredient, unit: unit, name: name) do
    {:ok,
     Map.merge(
       ingredient,
       %{
         amount: amount,
         unit: unit,
         name: Enum.join(name, " ")
       }
     )}
  end

  def parse_amount(amount) do
    divisor =
      amount
      |> String.split("/")
      |> Enum.map(&Integer.parse/1)

    case divisor do
      [:error | _] -> :error
      [_, :error] -> :error
      [{amt, _}] -> amt
      [{numerator, _}, {denominator, _}] -> numerator / denominator
    end
  end

  def extract_ingredient_note({:ok, ingredient}) do
    [name | note] = String.split(ingredient.name, ",")

    note =
      note
      |> Enum.reject(&(&1 == nil))
      |> Enum.join(",")
      |> String.trim()

    case note do
      "" ->
        {:ok, ingredient}

      note ->
        {:ok,
         Map.merge(
           ingredient,
           %{
             name: String.trim(name),
             note: note
           }
         )}
    end
  end
end
