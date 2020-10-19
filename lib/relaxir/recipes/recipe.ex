defmodule Relaxir.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.RecipeCategory

  schema "recipes" do
    field :directions, :string
    field :title, :string
    field :published, :boolean
    has_many :recipe_ingredients, RecipeIngredient, on_replace: :delete
    has_many :ingredients, through: [:recipe_ingredients, :ingredient]
    has_many :units, through: [:recipe_ingredients, :unit]
    has_many :recipe_categories, RecipeCategory, on_replace: :delete
    has_many :categories, through: [:recipe_categories, :category]
    belongs_to :user, Relaxir.Users.User

    timestamps()
  end

  def changeset(recipe, attrs) do
    recipe
    |> cast(strip_directions(attrs), [:title, :directions, :published, :user_id])
    |> cast_assoc(:recipe_categories)
    |> cast_assoc(:recipe_ingredients)
    |> validate_required([:title])
    |> unique_constraint([:title])
    |> find_ingredient_errors()
  end

  def strip_directions(attrs) do
    case Map.get(attrs, "directions") do
      nil -> attrs
      directions -> Map.merge(
        attrs,
        %{
          "directions" => String.trim(directions)
        }
      )
    end
  end

  def find_ingredient_errors(%{valid?: false} = changeset) do
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

  def find_ingredient_errors(c), do: c

  def find_error(error) do
    case error do
      {_, [{i, _}]} -> i
      {_, [i]} -> [i]
      {_, i} -> Enum.map(i, &find_error(&1))
      i -> i
    end
  end

  def find_error(error, acc) do
    case error do
      {_, [{i, _}]} -> acc ++ i
      {_, [i]} -> acc ++ [i]
      {_, i} -> Enum.map(i, &find_error(&1, acc))
      i -> acc ++ i
    end
  end
end
