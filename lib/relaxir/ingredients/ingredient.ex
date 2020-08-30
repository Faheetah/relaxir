defmodule Relaxir.Ingredients.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient

  @derive {Jason.Encoder, only: [:id, :name]}

  schema "ingredients" do
    field :name, :string
    field :description, :string
    has_many :recipe_ingredients, RecipeIngredient
    has_many :recipes, through: [:recipe_ingredients, :recipe], on_replace: :delete

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
    |> cast(attrs, [:name, :description])
    |> cast_assoc(:recipe_ingredients)
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
