[![Elixir CI](https://github.com/Faheetah/relaxir/actions/workflows/ci.yml/badge.svg)](https://github.com/Faheetah/relaxir/actions/workflows/ci.yml)

# Setup

Install Elixir

```
mix local.hex --force
mix local.rebar --force
mix deps.get
npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest
```

All environments need imagemagick

```
sudo apt install graphicsmagick
```

# Dev

```
mix ecto.reset
mix relaxir.add_user email=test@test username=test password=test admin=true
iex -S mix phx.server
```

Or inside of phx.server

```
Mix.Tasks.Relaxir.AddUser.run(["email=test@test", "username=test", "password=test", "admin=true"])
```

# Tests

Run unit tests, code quality tests, and static security scan

```
mix test --cover
mix credo
mix sobelow --skip -i Config.HTTPS
```

For local development, ensure all files are formatted, i.e.

```
mix format "{lib,test,config}/**/*.{ex,exs}"
```

Alternatively, a `tests.sh` script is included that will run all of the above and only display output of failures. This can be handy as a git hook.

# Prod

Increment version in mix.esx

Add a tag for the version, found with `mix relaxir.version`

Push with tags

Wait for the build job

```
mix relaxir.deploy
```

Or deploy from local workspace

```
mix relaxir.local_deploy relaxanddine.com
```

# USDA Data

**DEPRECATED: USDA nutrition is an absolute mess and has not been working correctly. The nutrition of base foods does not generally change over time as well. USDA functionality is going to be moved to browse only and eventually removed altogether. This information is going to be individually compiled for ingredients and updated. For now, nutrition is going to be phased out of the site.**

Can be found at https://fdc.nal.usda.gov/download-datasets.html

Load it in with:

```
mix relaxir.import Food ../../food-data/food.csv
```

Using sr_legacy_food

```
mkdir food-data
cd food-data
wget https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_%202019-04-02.zip
unzip FoodData_Central_sr_legacy_food_csv_%202019-04-02.zip
wget https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_Supporting_Data_csv_2021-10-28.zip
unzip FoodData_Central_Supporting_Data_csv_2021-10-28.zip
mix relaxir.import Food food-data/food.csv
mix relaxir.import Nutrient food-data/nutrient.csv
mix relaxir.import FoodNutrient food-data/food_nutrient.csv
```
