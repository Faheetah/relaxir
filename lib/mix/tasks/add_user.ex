defmodule Mix.Tasks.Relaxir.AddUser do
  use Mix.Task

  alias Relaxir.Repo
  alias Relaxir.Accounts

  @shortdoc "Create a user from command line"
  def run(params) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    data =
      params
      |> Enum.map(&String.split(&1, "="))
      |> Map.new(fn [k, v] -> {k, v} end)

    create = Accounts.register_user(%{
      email: String.downcase(data["email"]),
      password: data["password"],
      password_confirmation: data["password"],
      is_admin: data["admin"]
    })

    case create do
      {:ok, _} ->
        IO.puts "user created successfully"

      {:error, changeset} ->
        changeset
        |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        |> Enum.each(fn {type, [msg]} -> IO.puts("#{type} #{msg}") end)
    end
  end
end
