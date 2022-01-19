Recipe Ingredients

Polymorphism by adding another join table per polymorphic item and inverting the relationship, so RI is an extension of R

Recipes
id

ReicpeIngredient
recipe_id
amount
rank

Food
id

FoodRecipeIngredient
food_id
recipe_ingredient_id

RecipeRecipeIngredient
recipe_id
recipe_ingredient_id
