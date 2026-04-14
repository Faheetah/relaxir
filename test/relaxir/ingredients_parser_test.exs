defmodule Relaxir.IngredientsParserTest do
  use ExUnit.Case, async: true
  import Relaxir.Ingredients.Parser

  describe "parse_ingredients/1" do
    test "parses ingredients with units" do
      attrs = %{
        "ingredients" => [
          "2 cups flour",
          "1/2 teaspoon salt",
          "1.5 kg sugar, sifted"
        ]
      }

      result = parse_ingredients(attrs)

      assert %{"ingredients" => ingredients} = result
      assert is_list(ingredients)
      assert length(ingredients) == 3

      # Check that all ingredients were parsed
      flour = Enum.find(ingredients, fn i -> i.name == "flour" end)
      salt = Enum.find(ingredients, fn i -> i.name == "salt" end)
      sugar = Enum.find(ingredients, fn i -> i.name == "sugar" end)

      assert flour
      assert flour.amount == 2.0
      assert flour.unit == "cups"

      assert salt
      assert salt.amount == 0.5
      assert salt.unit == "teaspoons"

      assert sugar
      assert sugar.amount == 1.5
      assert sugar.unit == "kilograms"
      assert sugar.note == "sifted"
    end

    test "returns empty list for ingredients without units" do
      attrs = %{
        "ingredients" => [
          "1 egg",
          "2 tomatoes",
          "salt"
        ]
      }

      result = parse_ingredients(attrs)

      assert %{"ingredients" => ingredients} = result
      assert is_list(ingredients)
      assert length(ingredients) == 0
    end

    test "handles empty ingredients list" do
      attrs = %{"ingredients" => []}

      result = parse_ingredients(attrs)

      assert %{"ingredients" => []} = result
    end

    test "handles missing ingredients key" do
      attrs = %{"other_field" => "value"}

      # The function will fail when ingredients key is missing
      # as it tries to enumerate over nil
      assert_raise Protocol.UndefinedError, fn ->
        parse_ingredients(attrs)
      end
    end
  end

  describe "map_recipe_ingredient_fields/2" do
    test "returns attrs unchanged when amount or unit is nil" do
      attrs = %{name: "flour", amount: nil, unit: "cups"}
      units = []

      result = map_recipe_ingredient_fields(attrs, units)

      assert result == attrs
    end

    test "returns attrs unchanged when amount is nil" do
      attrs = %{name: "flour", amount: nil, unit: "cups"}
      units = []

      result = map_recipe_ingredient_fields(attrs, units)

      assert result == attrs
    end

    test "returns attrs unchanged when unit is nil" do
      attrs = %{name: "flour", amount: 2, unit: nil}
      units = []

      result = map_recipe_ingredient_fields(attrs, units)

      assert result == attrs
    end
  end
end
