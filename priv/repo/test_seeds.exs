case Relaxir.Users.get_by_email("test@test") do
  %Relaxir.Users.User{} -> true
  _ -> %Relaxir.Users.User{}
  |> Relaxir.Users.User.changeset(%{email: "test@test", password: "test", password_confirmation: "test", is_admin: true})
  |> Relaxir.Repo.insert!()
end

Code.require_file("priv/repo/unit_seed.exs")
