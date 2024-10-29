defmodule Horizon.MixProject do
  use Mix.Project

  def project do
    [
      app: :horizon,
      version: "0.1.3",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
        before_closing_body_tag: fn
          :html ->
            """
            <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
            <script>mermaid.initialize({startOnLoad: true})</script>
            """

          _ ->
            ""
        end
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
      files: [
        "lib",
        "priv",
        "samples",
        ".formatter.exs",
        "mix.exs",
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      links: %{"GitHub" => "https://github.com/jfreeze/horizon"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", runtime: false},
      {:ex_check, "~> 0.16.0", runtime: false, only: :dev},
      {:ex_doc, "~> 0.34", only: [:dev], runtime: false}
    ]
  end
end
