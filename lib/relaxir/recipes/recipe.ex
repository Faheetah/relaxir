defmodule Relaxir.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.Categories.Category
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.RecipeIngredient
  alias Relaxir.RecipeCategory
  alias Relaxir.Repo

  schema "recipes" do
    field :title, :string
    field :directions, :string
    field :note, :string
    field :description, :string
    field :published, :boolean
    field :gluten_free, :boolean
    field :keto, :boolean
    field :vegetarian, :boolean
    field :vegan, :boolean
    field :spicy, :boolean
    field :image_filename, :string
    has_many :recipe_ingredients, RecipeIngredient, on_replace: :delete, on_delete: :delete_all
    has_many :ingredients, through: [:recipe_ingredients, :ingredient]
    many_to_many :categories, Category, join_through: RecipeCategory, on_replace: :delete, on_delete: :delete_all
    has_one :ingredient, Ingredient, foreign_key: :source_recipe_id
    belongs_to :user, Relaxir.Accounts.User

    timestamps()
  end

  @cast_attrs [
    :title,
    :gluten_free,
    :keto,
    :vegetarian,
    :vegan,
    :spicy,
    :description,
    :directions,
    :note,
    :published,
    :user_id,
    :image_filename
  ]

  def changeset(recipe, attrs, insert? \\ true) do
    recipe
    |> cast(strip_directions(attrs), @cast_attrs)
    |> put_assoc(:categories, parse_categories(attrs, insert?))
    |> put_assoc(:recipe_ingredients, parse_ingredients(Map.get(attrs, "recipe_ingredients", []), insert?))
    |> validate_required([:title])
    |> unique_constraint(:title)
    |> find_ingredient_errors()
  end

  defp parse_categories(attrs, insert?) do
    (attrs["categories"] || [])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.filter(&String.match?(&1, ~r/[a-z\s\-]/))
    |> Enum.map(&get_or_insert_category(&1, insert?))
  end

  def get_or_insert_category(name, false), do: %Category{name: name}

  def get_or_insert_category(name, true) do
    name = String.downcase(name)
    Repo.get_by(Category, name: name) || Repo.insert!(%Category{name: name})
  end

  defp strip_directions(attrs) do
    case Map.get(attrs, "directions") do
      nil ->
        attrs

      directions ->
        Map.merge(
          attrs,
          %{
            "directions" => String.trim(directions)
          }
        )
    end
  end

  defp find_ingredient_errors(%{valid?: false} = changeset) do
    traverse_errors(changeset, fn _, _field, {msg, _} ->
      msg
    end)
    # does not work with anything but recipe_ingredients apparently
    |> Map.get(:recipe_ingredients, [])
    |> Enum.find([], &(&1 != %{}))
    |> Enum.reduce(changeset, fn errors, acc ->
      add_error(
        acc,
        :recipe_ingredients,
        find_error(errors)
        |> Enum.join(", ")
      )
    end)
  end

  defp find_ingredient_errors(c), do: c

  defp find_error(error) do
    case error do
      {_, [{i, _}]} -> i
      {_, [i]} -> [i]
      {_, i} -> Enum.map(i, &find_error(&1))
      i -> i
    end
  end

  defp parse_ingredients(recipe_ingredients, false), do: recipe_ingredients

  defp parse_ingredients(recipe_ingredients, true) do
    recipe_ingredients
    |> Enum.with_index()
    |> Enum.map(fn {ingredient, index} -> format_ingredients(ingredient, index) end)
    |> Enum.reject(fn ri -> ri.ingredient.name == "" end)
  end

  # Delimiter for serializing ingredients - using :: to avoid conflicts with ingredient names
  @ingredient_delimiter "||"

  defp format_ingredients(recipe_ingredient, order) do
    # Split on the delimiter, but only into 4 parts max to handle any edge cases
    parts = String.split(recipe_ingredient, @ingredient_delimiter, parts: 4)

    # Pad with empty strings if less than 4 parts
    [amount, unit_name, ingredient_name, note] = parts ++ List.duplicate("", 4 - length(parts))

    # Parse unit using the unit library to get the full name
    unit_map =
      if unit_name != "" and not is_nil(unit_name) do
        # Try to parse the unit string to get the unit
        # If amount is empty, use a dummy amount for parsing
        parse_string = if amount == "", do: "1 #{unit_name}", else: "#{amount} #{unit_name}"

        # Try parsing as volume first, then as weight
        parsed_unit =
          case Relaxir.Units.parse_unit_string_volume(parse_string) do
            {:ok, unit, _rest} ->
              unit

            _ ->
              case Relaxir.Units.parse_unit_string_weight(parse_string) do
                {:ok, unit, _rest} -> unit
                _ -> nil
              end
          end

        if parsed_unit do
          # Get the unit name from the parsed unit
          unit_name = Relaxir.Units.get_unit_name(parsed_unit)
          if unit_name, do: %{name: unit_name}, else: nil
        else
          # If parsing fails, create a unit map with the original unit name
          %{name: unit_name}
        end
      else
        nil
      end

    ingredient = Repo.get_by(Ingredient, name: ingredient_name)

    %{
      amount: parse_amount(amount),
      unit: unit_map,
      note: note,
      order: order,
      ingredient: ingredient || %{name: ingredient_name}
    }
  end

  defp parse_amount(""), do: nil

  defp parse_amount(amount) do
    # Handle fractions like "1/2" by converting to float
    case String.split(amount, "/") do
      [numerator, denominator] ->
        case {Float.parse(numerator), Float.parse(denominator)} do
          {{n, _}, {d, _}} when d != 0 -> n / d
          _ -> Float.parse(amount) |> elem(0)
        end

      _ ->
        Float.parse(amount) |> elem(0)
    end
  end

  def get_or_insert_ingredient(name, false), do: %Ingredient{name: name}

  def get_or_insert_ingredient(name, true) do
    name = String.downcase(name)
    Repo.get_by(Ingredient, name: name) || Repo.insert!(%Ingredient{name: name})
  end
end
