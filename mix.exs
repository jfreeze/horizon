defmodule Horizon.Ops.MixProject do
  use Mix.Project

  def project do
    [
      app: :horizon_ops,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md"]
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
      {:ex_doc, "~> 0.34", runtime: false},
      {:dialyxir, "~> 1.4", runtime: false}
    ]
  end
end
