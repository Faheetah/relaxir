defmodule Relaxir.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.RecipeCategory

  schema "recipes" do
    field :directions, :string
    field :title, :string
    has_many :recipe_ingredients, RecipeIngredient, on_replace: :delete
    has_many :ingredients, through: [:recipe_ingredients, :ingredient]
    has_many :units, through: [:recipe_ingredients, :unit]
    has_many :recipe_categories, RecipeCategory, on_replace: :delete
    has_many :categories, through: [:recipe_categories, :category]

    timestamps()
  end

  def changeset(recipe, attrs) do
    recipe
    |> cast(strip_description(attrs), [:title, :directions])
    |> cast_assoc(:recipe_categories)
    |> cast_assoc(:recipe_ingredients)
    |> validate_required([:title])
    |> unique_constraint([:title])
    |> find_ingredient_errors()
  end

  def strip_description(attrs) do
    Map.merge(
      attrs,
      %{
        "directions" => String.trim(Map.get(attrs, "directions", ""))
      }
    )
  end

  def find_ingredient_errors(%{valid?: false} = changeset) do
      traverse_errors(changeset, fn _, _field, {msg, _} ->
        msg
      end)
      |> Enum.reduce(changeset, fn {field, errors}, acc ->
        add_error(
          acc,
          field,
          Enum.find(errors, &(&1 != %{}))
          |> Enum.reduce([], &find_error/2)
          |> hd
          |> Enum.join(", ")
        )
      end)
  end

  def find_ingredient_errors(c), do: c

  def find_error(error, acc) do
    case error do
      {_, [{i, _}]} -> acc ++ i
      {_, [i]} -> acc ++ [i]
      {_, i} -> Enum.map(i, &find_error(&1, acc))
      i -> acc ++ i
    end
  end
end
