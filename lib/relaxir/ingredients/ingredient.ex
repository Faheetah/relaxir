defmodule Relaxir.Ingredients.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.Usda.Food

  @derive {Jason.Encoder, only: [:id, :name]}

  schema "ingredients" do
    field :name, :string
    field :description, :string
    has_many :child_ingredients, __MODULE__, foreign_key: :parent_ingredient_id
    has_many :recipe_ingredients, RecipeIngredient
    has_many :recipes, through: [:recipe_ingredients, :recipe], on_replace: :delete
    belongs_to :food, Food
    belongs_to :parent_ingredient, __MODULE__

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
    |> cast(attrs, [:name, :description, :parent_ingredient_id])
    |> cast_assoc(:recipe_ingredients)
    |> cast_assoc(:food)
    |> cast_assoc(:parent_ingredient)
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
