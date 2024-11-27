defmodule Horizon.MixProject do
  use Mix.Project

  def project do
    [
      app: :horizon,
      version: "0.2.2",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        assets: %{
          "docs/freebsd-install" => "freebsd-install",
          "docs/hetzner-cloud" => "hetzner-cloud",
          "docs/hetzner-template-install" => "hetzner-template-install",
          "docs/proxmox-create-vm" => "proxmox-create-vm"
        },
        extras: [
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
          "CHANGELOG.md",
          "LICENSE.md"
        ],
        groups_for_extras: [
          "Installation Guides": [
            "docs/freebsd-template-setup.md",
            "docs/hetzner-cloud.md",
            "docs/hetzner-cloud-host-instantiation.md",
            "docs/freebsd-install.md"
          ],
          "Configuration Files": [
            "docs/build_conf.md",
            "docs/web_proxy_conf.md",
            "docs/postgres_conf.md",
            "docs/postgres_backup_conf.md"
          ]
        ],
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
      {:ex_doc, "~> 0.34", only: [:dev], runtime: false},
      {:slugify, "~> 1.3"}
    ]
  end
end
