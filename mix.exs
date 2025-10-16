defmodule EctoNestedChangeset.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/woylie/ecto_nested_changeset"

  def project do
    [
      app: :ecto_nested_changeset,
      version: @version,
      name: "Ecto Nested Changeset",
      description: description(),
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_file: {:no_warn, ".plts/dialyzer.plt"}
      ],
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def cli do
    [
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "== 1.0.14", only: :test},
      {:credo, "== 1.7.12", only: [:dev, :test], runtime: false},
      {:dialyxir, "== 1.4.5", only: [:dev], runtime: false},
      {:ecto, "~> 3.7"},
      {:ecto_sql, "== 3.12.1", only: :test},
      {:ex_doc, "== 0.38.2", only: :dev, runtime: false},
      {:excoveralls, "== 0.18.5", only: :test},
      {:stream_data, "== 1.2.0", only: [:dev, :test]}
    ]
  end

  defp description do
    "Helpers for manipulating nested Ecto changesets"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blob/main/CHANGELOG.md",
        "Sponsor" => "https://github.com/sponsors/woylie"
      },
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "main"
    ]
  end
end
