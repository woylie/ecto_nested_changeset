defmodule Nested.MixProject do
  use Mix.Project

  def project do
    [
      app: :nested,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Nested.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ecto_nested_changeset, path: ".."},
      {:ecto_sql, "== 3.13.2"},
      {:esbuild, "== 0.9.0", runtime: Mix.env() == :dev},
      {:floki, "== 0.37.1", only: :test},
      {:heroicons, "== 0.5.6"},
      {:jason, "== 1.4.4"},
      {:phoenix, "== 1.7.21"},
      {:phoenix_ecto, "== 4.6.5"},
      {:phoenix_html, "== 4.2.1"},
      {:phoenix_live_reload, "== 1.6.1", only: :dev},
      {:phoenix_live_view, "== 1.0.12"},
      {:plug_cowboy, "== 2.7.4"},
      {:postgrex, "== 0.20.0"},
      {:tailwind, "== 0.3.1", runtime: Mix.env() == :dev}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
