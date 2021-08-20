defmodule Relaxir.Search do
  def search_for(module, name, terms) do
    case Invert.get(module, name, terms) do
      {:ok, results} -> results
      {:error, :not_found} -> []
    end
    |> Enum.sort_by(
      fn {[term, _], score} ->
        score - String.length(term) / 1000
      end,
      :desc
    )
  end
end
