defmodule Horizon.MixProject do
  use Mix.Project

  @version "0.2.5"

  def project do
    [
      app: :horizon,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: &docs/0,
      description: "Library for managing Elixir/Phoenix deployments",
      package: package(),
      source_url: "https://github.com/jfreeze/horizon",
      dialyzer: [
        plt_add_apps: [:mix]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      assets: %{
        "docs/images" => "images"
      },
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp extras do
    [
      "README.md",
      "docs/Deploying-with-Horizon.md",
      "docs/horizon-helper-scripts.md",
      "docs/sample-host-configurations.md",
      "docs/freebsd-template-setup.md",
      "docs/proxy-conf.livemd",
      "docs/hetzner-cloud.md",
      "docs/hetzner-cloud-host-instantiation.md",
      "docs/freebsd-install.md",
      "docs/build_conf.md",
      "docs/web_proxy_conf.md",
      "docs/postgres_conf.md",
      "docs/postgres_backup_conf.md",
      "docs/proxmox.md",
      "CHANGELOG.md",
      "LICENSE.md"
    ]
  end

  defp groups_for_extras do
    [
      "Installation Guides": [
        "docs/freebsd-template-setup.md",
        "docs/hetzner-cloud.md",
        "docs/hetzner-cloud-host-instantiation.md",
        "docs/freebsd-install.md",
        "docs/proxmox.md"
      ],
      "Configuration Files": [
        "docs/build_conf.md",
        "docs/web_proxy_conf.md",
        "docs/postgres_conf.md",
        "docs/postgres_backup_conf.md"
      ]
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    <script>mermaid.initialize({startOnLoad: true})</script>

    """
  end

  defp before_closing_body_tag(_format), do: ""

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
      links: %{
        "GitHub" => "https://github.com/jfreeze/horizon",
        "Changelog" => "https://github.com/jfreeze/horizon/blob/main/CHANGELOG.md"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", runtime: false},
      {:ex_check, "~> 0.16.0", runtime: false, only: :dev},
      {:ex_doc, "~> 0.34", only: :docs},
      {:makeup_diff, "~> 0.1.1", only: :docs},
      {:slugify, "~> 1.3"}
    ]
  end
end
