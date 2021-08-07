# Setup

Install Elixir

mix local.hex --force

mix local.rebar --force

mix deps.get

npm install --prefix ./assets

npm run deploy --prefix ./assets

mix phx.digest

# Dev

`mix ecto.reset`
`mix relaxir.add_user email=test@test password=test admin=true`
`mix relaxir.seed_db`
`iex -S mix phx.server`

Or inside of phx.server

Mix.Tasks.Relaxir.AddUser.run(["email=test@test", "password=test", "admin=true"])
Mix.Tasks.Relaxir.SeedDb.run([])

# Prod

Increment version in mix.esx

Add a tag for the version, found with `mix relaxir.version`

Push with tags

Wait for the build job

`mix relaxir.deploy`

# USDA Data

Can be found at https://fdc.nal.usda.gov/portal-data/external/dataDictionary

Load it in with:

```
mix relaxir.import Food ../../food-data/food.csv
```
