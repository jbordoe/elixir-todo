defmodule Todo.MixProject do
  use Mix.Project

  def project do
    [
      app: :todo,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Todo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:gproc, "~> 1.0"},
      {:mock, "~> 0.3.9", only: :test},
      {:cowboy, "~> 2.13"},
      {:plug_cowboy, "~> 2.5"},
      {:plug, "~> 1.17"},
      {:httpoison, "~> 2.2"}
    ]
  end
end
