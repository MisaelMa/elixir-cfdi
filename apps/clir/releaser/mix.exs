defmodule Releaser.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/MisaelMa/releaser"

  def project do
    [
      app: :releaser,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Monorepo versioning, changelog, and Hex publishing for Elixir poncho/umbrella projects",
      releaser: [publish: true],
      docs: [
        main: "readme",
        source_url: @source_url,
        extras: [
          "README.md",
          "guides/getting-started.md",
          "guides/pre-release-tags.md",
          "guides/publishing-to-hex.md",
          "guides/changelog-and-hooks.md",
          "guides/monorepo-patterns.md"
        ],
        groups_for_extras: [
          Guides: ~r/guides\/.*/
        ],
        groups_for_modules: [
          Core: [
            Releaser,
            Releaser.Config,
            Releaser.Version,
            Releaser.Workspace,
            Releaser.App
          ],
          "Dependency Graph": [
            Releaser.Graph,
            Releaser.Cascade
          ],
          Publishing: [
            Releaser.Publisher,
            Releaser.HexStatus
          ],
          Changelog: [
            Releaser.Changelog,
            Releaser.FileSync
          ],
          Hooks: [
            Releaser.Hooks.PreHook,
            Releaser.Hooks.PostHook,
            Releaser.Hooks.GitTag,
            Releaser.Hooks.ChangelogHook
          ],
          Git: [
            Releaser.Git
          ],
          "Mix Tasks": [
            Mix.Tasks.Releaser.Bump,
            Mix.Tasks.Releaser.Graph,
            Mix.Tasks.Releaser.Publish,
            Mix.Tasks.Releaser.Status,
            Mix.Tasks.Releaser.Changelog
          ],
          Utilities: [
            Releaser.UI
          ]
        ]
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib guides mix.exs README.md LICENSE)
    ]
  end
end
