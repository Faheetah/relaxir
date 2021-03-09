defmodule Mix.Tasks.Relaxir.AddUser do
  use Mix.Task

  alias Relaxir.Repo
  alias Relaxir.Users.User

  @shortdoc "Create a user from command line"
  def run(params) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    data =
      params
      |> Enum.map(&String.split(&1, "="))
      |> Map.new(fn [k, v] -> {k, v} end)

    %User{}
    |> User.changeset(%{
      email: String.downcase(data["email"]),
      password: data["password"],
      password_confirmation: data["password"],
      is_admin: data["admin"]
    })
    |> Repo.insert()
  end
end
