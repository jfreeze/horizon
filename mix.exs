defmodule Horizon.MixProject do
  use Mix.Project

  def project do
    [
      app: :horizon,
      version: "0.1.2",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      description: "Library for managing Elixir/Phoenix deployments",
      package: package(),
      source_url: "https://github.com/jfreeze/horizon"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: "horizon",
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => "https://github.com/jfreeze/horizon"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", runtime: false},
      {:ex_check, "~> 0.16.0"},
      {:ex_doc, "~> 0.34", runtime: false}
    ]
  end
end
