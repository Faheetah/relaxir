defmodule Relaxir.UnitParsingTest do
  use Relaxir.DataCase, async: true

  alias Relaxir.Recipes
  alias Relaxir.Units

  describe "unit parsing with new API" do
    test "parses weight units correctly" do
      # Test parsing of weight units
      result1 = Units.parse_unit_string_weight("2 g flour")
      assert is_tuple(result1)
      assert tuple_size(result1) == 3
      assert elem(result1, 0) == :ok
      assert is_binary(elem(result1, 2))
      assert elem(result1, 2) == "flour"

      result2 = Units.parse_unit_string_weight("1.5 kg sugar")
      assert is_tuple(result2)
      assert tuple_size(result2) == 3
      assert elem(result2, 0) == :ok
      assert is_binary(elem(result2, 2))
      assert elem(result2, 2) == "sugar"

      result3 = Units.parse_unit_string_weight("8 oz butter")
      assert is_tuple(result3)
      assert tuple_size(result3) == 3
      assert elem(result3, 0) == :ok
      assert is_binary(elem(result3, 2))
      assert elem(result3, 2) == "butter"
    end

    test "parses volume units correctly" do
      # Test parsing of volume units
      result1 = Units.parse_unit_string_volume("1 c milk")
      assert is_tuple(result1)
      assert tuple_size(result1) == 3
      assert elem(result1, 0) == :ok
      assert is_binary(elem(result1, 2))
      assert elem(result1, 2) == "milk"

      result2 = Units.parse_unit_string_volume("2 tbsp water")
      assert is_tuple(result2)
      assert tuple_size(result2) == 3
      assert elem(result2, 0) == :ok
      assert is_binary(elem(result2, 2))
      assert elem(result2, 2) == "water"

      result3 = Units.parse_unit_string_volume("3 tsp oil")
      assert is_tuple(result3)
      assert tuple_size(result3) == 3
      assert elem(result3, 0) == :ok
      assert is_binary(elem(result3, 2))
      assert elem(result3, 2) == "oil"
    end

    test "avoids celsius vs cups conflict" do
      # Test that we can parse "c" as cups in volume context
      result1 = Units.parse_unit_string_volume("1 c flour")
      assert is_tuple(result1)
      assert tuple_size(result1) == 3
      assert elem(result1, 0) == :ok
      assert is_binary(elem(result1, 2))
      assert elem(result1, 2) == "flour"

      # Test that we don't parse "c" as celsius in weight context
      assert {:error, _} = Units.parse_unit_string_weight("1 c flour")
    end

    test "parse_ingredient_with_units handles weight units" do
      # Test weight unit parsing
      assert {:ok, [amount, unit, ingredient, note]} = Recipes.parse_ingredient_with_units("2 g flour")
      assert amount == "2.0"
      assert unit == "gram"
      assert ingredient == "flour"
      assert note == ""

      assert {:ok, [amount, unit, ingredient, note]} = Recipes.parse_ingredient_with_units("8 oz butter, softened")
      assert amount == "8.0"
      assert unit == "ounce"
      assert ingredient == "butter"
      assert note == "softened"
    end

    test "parse_ingredient_with_units handles volume units" do
      # Test volume unit parsing
      assert {:ok, [amount, unit, ingredient, note]} = Recipes.parse_ingredient_with_units("1 c flour")
      assert amount == "1.0"
      assert unit == "cup"
      assert ingredient == "flour"
      assert note == ""

      assert {:ok, [amount, unit, ingredient, note]} = Recipes.parse_ingredient_with_units("2 tbsp water, warm")
      assert amount == "2.0"
      assert unit == "tablespoon"
      assert ingredient == "water"
      assert note == "warm"
    end

    test "parse_ingredient_with_units returns error for unknown units" do
      # Test that unknown units return an error
      assert {:error, _reason} = Recipes.parse_ingredient_with_units("1 something, note")
    end

    test "parse_ingredient_with_units handles milliliter units" do
      # Test milliliter unit parsing
      assert {:ok, [amount, unit, ingredient, note]} = Recipes.parse_ingredient_with_units("1 ml milk")
      assert amount == "1.0"
      assert unit == "milliliter"
      assert ingredient == "milk"
      assert note == ""
    end
  end
end
