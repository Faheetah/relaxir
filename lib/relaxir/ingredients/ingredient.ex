defmodule Relaxir.Ingredients.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.Recipes.Recipe
  alias Relaxir.RecipeIngredient

  schema "ingredients" do
    field :name, :string
    field :singular, :string
    field :description, :string
    field :image_filename, :string
    # has_many :child_ingredients, __MODULE__, foreign_key: :parent_ingredient_id
    has_many :recipe_ingredients, RecipeIngredient
    has_many :recipes, through: [:recipe_ingredients, :recipe], on_replace: :delete
    # belongs_to :parent_ingredient, __MODULE__
    belongs_to :source_recipe, Recipe

    timestamps()
  end

  def changeset(ingredient, attrs) do
    attrs =
      cond do
        Map.get(attrs, "name") -> Map.update!(attrs, "name", &String.downcase/1)
        Map.get(attrs, :name) -> Map.update!(attrs, :name, &String.downcase/1)
        true -> attrs
      end

    ingredient
    |> cast(attrs, [:name, :singular, :description, :parent_ingredient_id, :source_recipe_id])
    |> cast_assoc(:recipe_ingredients)
    |> cast_assoc(:parent_ingredient)
    |> cast_assoc(:source_recipe)
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
