defmodule RelaxirWeb.FormattingComponentsTest do
  use RelaxirWeb.ConnCase, async: true

  describe "parse_decimal_to_fraction/1" do
    test "gets valid results up to 1..100/1..100" do
      nums =
        for i <- 1..100, j <- 1..100 do
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
  end
end
