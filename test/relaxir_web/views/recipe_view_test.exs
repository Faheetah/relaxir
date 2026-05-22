defmodule RelaxirWeb.FormattingComponentsTest do
  use RelaxirWeb.ConnCase, async: true

  describe "parse_decimal_to_fraction/1" do
    # Test that fractions up to 1/99 are representable (max_denominator = 99)
    test "gets valid results up to 1..20/1..100" do
      nums =
        for i <- 1..20, j <- 1..100 do
          a = RelaxirWeb.FormattingComponents.parse_decimal_to_fraction(i / j)
          whole = trunc((i - rem(i, j)) / j)
          fraction = rem(i, j)
          gcd = Integer.gcd(fraction, j)
          n = trunc(fraction / gcd)
          d = trunc(j / gcd)

          expected =
            [whole, n]
            |> case do
              [0, _] -> "#{n}/#{d}"
              [_, 0] -> whole
              _ -> "#{whole} #{n}/#{d}"
            end

          {a, expected}
        end
        |> Enum.reject(fn {actual, expected} -> actual == expected end)

      assert nums == []
    end

    test "handles common fractions correctly" do
      assert RelaxirWeb.FormattingComponents.parse_decimal_to_fraction(0.5) == "1/2"
      assert RelaxirWeb.FormattingComponents.parse_decimal_to_fraction(0.25) == "1/4"
      assert RelaxirWeb.FormattingComponents.parse_decimal_to_fraction(0.75) == "3/4"
      assert RelaxirWeb.FormattingComponents.parse_decimal_to_fraction(1.5) == "1 1/2"
      assert RelaxirWeb.FormattingComponents.parse_decimal_to_fraction(2.0) == 2
    end
  end
end
