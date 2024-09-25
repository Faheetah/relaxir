defmodule Relaxir.MixProject do
  use Mix.Project

  def project do
    [
      app: :relaxir,
      version: "0.9.0",
      url: "https://github.com/Faheetah/relaxir/",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Relaxir.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # TODO remove if migrated fully to live view
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.6"},
      # Phoenix/Ecto related
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_view, "~> 1.0.0-rc.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      # telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      # misc required for app
      {:gettext, "~> 0.20"},
      {:jason, "~>1.4"},
      {:bcrypt_elixir, "~> 3.1"},
      {:earmark, "~> 1.4"},
      {:csv, "~> 3.0.5"},
      {:inflex, "~> 2.1.0"},
      {:invert, git: "https://github.com/faheetah/invert", tag: "0.3.0"},
      # test and code quality
      {:mix_test_watch, "~> 1.1", runtime: false, only: :dev},
      {:credo, "~> 1.7", only: :dev},
      {:excoveralls, "~> 0.17", only: :test},
      {:sobelow, "~> 0.13", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.setup_dev": [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/dev_seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/test_seeds.exs",
        "test"
      ],
      "test.clean": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/test_seeds.exs"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
