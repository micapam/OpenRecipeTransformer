defmodule SerumRecipes.MixProject do
  use Mix.Project

  def project do
    [
      app: :serum_recipes,
      description: "A plugin for the Serum site generator to loads recipes from schema.org format",
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        licenses: ["CC0-1.0"],
        links: %{"GitHub" => "https://github.com/micapam/SerumRecipes"}
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
      { :serum, "~> 1.5.1" },
      { :yaml_elixir, "~> 2.8" },
      { :ex_doc, ">= 0.0.0", only: :dev, runtime: false },
      { :recase, "~> 0.5" }
    ]
  end
end
