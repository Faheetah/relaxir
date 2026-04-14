defmodule Relaxir.UnitsTest do
  use Relaxir.DataCase

  alias Relaxir.Units
  alias Unit, as: UnitLib

  setup do
    :ok
  end

  @singular "tinyspoon"
  @plural "tinyspoons"
  @abbreviation "tiny"
  @abbreviation_plural "tinys"

  describe "units" do
    test "creates a unit" do
      {:ok, unit} = Units.create_unit(%{name: @singular, abbreviation: @abbreviation})
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "creates a unit as singular" do
      {:ok, unit} = Units.create_unit(%{name: @plural, abbreviation: @abbreviation_plural})
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "gets a unit by singular name" do
      Units.create_unit(%{name: @singular, abbreviation: @abbreviation})
      unit = Units.get_unit_by_name(@singular)
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "gets a unit by plural name" do
      Units.create_unit(%{name: @plural, abbreviation: @abbreviation_plural})
      unit = Units.get_unit_by_name(@plural)
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "gets a unit by plural abbreviation" do
      Units.create_unit(%{name: @plural, abbreviation: @abbreviation_plural})
      unit = Units.get_unit_by_name(@abbreviation_plural)
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "returns nil for missing unit" do
      unit = Units.get_unit_by_name(@singular)
      assert unit == nil
    end

    test "lists all units" do
      units = Units.list_units()
      # The list should contain existing units from the database
      assert Enum.count(units) > 0
      # Check that a known database unit is in the list
      assert Enum.find(units, fn u -> u.name == "cup" end)
    end
  end

  describe "unit library integration" do
    test "converts unit library unit to database unit" do
      # Get existing database unit that maps to a unit library unit
      db_unit = Units.get_unit_by_name("cup")

      # Create a unit library unit
      unit_lib_unit = %UnitLib.Cup{value: 2.0}

      # Convert to database unit
      converted_db_unit = Units.unit_to_db_unit(unit_lib_unit)

      assert converted_db_unit != nil
      assert converted_db_unit.name == db_unit.name
    end

    test "converts database unit to unit library unit" do
      # Get existing database unit
      db_unit = Units.get_unit_by_name("gram")

      # Convert to unit library unit
      unit_lib_unit = Units.db_unit_to_unit(db_unit, 100.0)

      assert unit_lib_unit != nil
      assert unit_lib_unit.__struct__ == UnitLib.Gram
      assert unit_lib_unit.value == 100.0
    end

    test "parses unit string using unit library" do
      # Parse a string with the unit library
      result = Units.parse_unit_string("2 cups of flour")

      assert {:ok, unit, rest} = result
      assert unit.__struct__ == UnitLib.Cup
      assert unit.value == 2.0
      assert String.trim(rest) == "of flour"
    end

    test "converts unit to string" do
      unit = %UnitLib.Gram{value: 1.0}
      result = Units.unit_to_string(unit)

      assert result == "1 gram"
    end

    test "adds units together" do
      unit1 = %UnitLib.Gram{value: 1000.0}
      unit2 = %UnitLib.Kilogram{value: 1.0}

      result = Units.add_units(unit1, unit2)

      # The Unit library returns the unit directly, not a tuple
      assert result.__struct__ == UnitLib.Gram
      assert result.value == 2000.0
    end

    test "converts unit to different type" do
      unit = %UnitLib.Gram{value: 1000.0}

      result = Units.convert_unit(unit, UnitLib.Kilogram)

      # The Unit library returns the unit directly, not a tuple
      assert result.__struct__ == UnitLib.Kilogram
      assert result.value == 1.0
    end
  end
end
