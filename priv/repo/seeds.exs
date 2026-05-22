alias Relaxir.Categories
alias Relaxir.Ingredients
alias Relaxir.Ingredients.Ingredient
alias Relaxir.Repo

# Create categories
~w[
  appetizers
  breakfast
  lunch
  mains
  sides
  condiments
  dessert
  drinks
  baking
]
|> Enum.map(fn c -> %{name: c} end)
|> Enum.each(&Categories.create_category/1)

# Helper to get or create ingredient
get_or_create_ingredient = fn name, parent_id ->
  case Repo.get_by(Ingredient, name: name) do
    nil ->
      Ingredients.create_ingredient(%{
        name: name,
        parent_ingredient_id: parent_id
      })

    existing ->
      {:ok, existing}
  end
end

# Create ingredients with hierarchical structure
# Meat category
{:ok, meat} = get_or_create_ingredient.("meat", nil)
{:ok, beef} = get_or_create_ingredient.("beef", meat.id)
{:ok, ribeye} = get_or_create_ingredient.("ribeye", beef.id)
{:ok, chuck} = get_or_create_ingredient.("chuck", beef.id)

# Poultry
{:ok, poultry} = get_or_create_ingredient.("poultry", meat.id)
{:ok, chicken} = get_or_create_ingredient.("chicken", poultry.id)
{:ok, chicken_thighs} = get_or_create_ingredient.("chicken thighs", chicken.id)
{:ok, chicken_breast} = get_or_create_ingredient.("chicken breast", chicken.id)

# Vegetables
{:ok, vegetables} = get_or_create_ingredient.("vegetables", nil)
{:ok, peppers} = get_or_create_ingredient.("peppers", vegetables.id)
{:ok, jalapenos} = get_or_create_ingredient.("jalapenos", peppers.id)

# Grains
{:ok, grains} = get_or_create_ingredient.("grains", nil)
{:ok, flour} = get_or_create_ingredient.("flour", grains.id)
{:ok, rice} = get_or_create_ingredient.("rice", grains.id)
{:ok, brown_rice} = get_or_create_ingredient.("brown rice", rice.id)

# Additives
{:ok, baking} = get_or_create_ingredient.("additives", nil)
{:ok, baking_powder} = get_or_create_ingredient.("baking powder", baking.id)
{:ok, baking_soda} = get_or_create_ingredient.("baking soda", baking.id)
{:ok, xanthan_gum} = get_or_create_ingredient.("xanthan gum", baking.id)
{:ok, cornstarch} = get_or_create_ingredient.("cornstarch", baking.id)
{:ok, vanilla_extract} = get_or_create_ingredient.("vanilla extract", baking.id)
{:ok, active_dry_yeast} = get_or_create_ingredient.("active dry yeast", baking.id)
