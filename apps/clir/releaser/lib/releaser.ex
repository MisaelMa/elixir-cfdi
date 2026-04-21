defmodule Releaser do
  @moduledoc """
  Monorepo versioning, changelog, and Hex publishing for Elixir.

  Releaser provides a complete toolkit for managing multi-package Elixir projects
  (poncho or umbrella). It handles version bumping with pre-release tags, cascading
  version changes through dependency graphs, changelog generation from git commits,
  and topological publishing to Hex.

  ## Features

  - **Versioning** — SemVer bump with pre-release tags (`dev`, `beta`, `rc`), cascade to dependents
  - **Publishing** — Publish all packages to Hex in dependency order, replacing `path:` deps automatically
  - **Changelog** — Generate changelogs from conventional git commits
  - **Hooks** — Pre/post-bump hooks for git tagging, changelog generation, custom logic
  - **Status** — Compare local versions against Hex to see what needs publishing

  ## Quick start

  Add to your root `mix.exs`:

      {:releaser, "~> 0.1", only: :dev, runtime: false}

  Then use:

      mix releaser.bump my_app patch --tag dev
      mix releaser.graph
      mix releaser.status
      mix releaser.publish --dry-run

  ## Configuration

  Configure in your root `mix.exs` project config:

      def project do
        [
          app: :my_project,
          releaser: [
            apps_root: "apps",
            changelog: [anchors: %{"feat" => "Added", "fix" => "Fixed"}],
            hooks: [post: [Releaser.Hooks.GitTag]],
            publisher: [package_defaults: [licenses: ["MIT"]]]
          ]
        ]
      end

  See `Releaser.Config` for all options.
  """

  @doc """
  Returns the current releaser configuration merged with defaults.
  """
  def config do
    Releaser.Config.load()
  end
end
