defmodule EctoNestedChangeset.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_nested_changeset,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
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
      {:credo, "~> 1.5.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:ecto, "~> 3.7"},
      {:ecto_sql, "~> 3.7", only: :test},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:stream_data, "~> 0.5", only: [:dev, :test]}
    ]
  end
end
