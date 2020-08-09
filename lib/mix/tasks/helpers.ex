defmodule Relaxir.Mix.Helpers do
  def parse_args(params) do
    parsed_params = params
    |> Enum.map(&split_args/1)
    |> Enum.map(&get_flag/1)
    |> Enum.map(&convert_pairs/1)
    positionals = Enum.filter(parsed_params, fn x -> is_list(x) && length(x) == 1 end) |> Enum.map(&(List.first(&1)))
    keywords = Enum.filter(parsed_params, fn x -> is_tuple(x) end)
    [{:positionals, positionals} | keywords]
  end

  defp convert_pairs(arg) do
    case arg do
      [k, v] -> {String.to_existing_atom(k), v}
      _ -> arg
    end
  end

  defp split_args(arg) do
    String.split(arg, "=", parts: 2)
  end

  defp get_flag(arg) do
    [key | val] = arg
    cond do
      String.starts_with? key, "--" -> 
        "--" <> rest = key
        case val do
          [] -> [rest, true] 
          _ -> [rest, List.first val]
        end
      true -> arg
    end
  end
end
