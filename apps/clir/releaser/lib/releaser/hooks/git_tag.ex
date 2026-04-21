defmodule Releaser.Hooks.GitTag do
  @moduledoc """
  Built-in post-hook that creates a git commit and tag after bumping.

  Stages changed `mix.exs` files, creates a commit with a descriptive message,
  and tags with the app name and version.

  ## Commit format

      bump: cfdi_xml 4.0.18 → 4.0.19

  ## Tag format

      cfdi_xml-v4.0.19

  Add to your config:

      releaser: [hooks: [post: [Releaser.Hooks.GitTag]]]
  """

  @behaviour Releaser.Hooks.PostHook

  alias Releaser.{Git, UI}

  @impl true
  def run(%{changes: changes}) do
    # Stage all changed mix.exs files
    mix_files = Enum.map(changes, fn %{path: path} -> Path.join(path, "mix.exs") end)
    Git.add(mix_files)

    # Build commit message
    summary =
      changes
      |> Enum.map(fn %{app: app, old: old, new: new} -> "  #{app} #{old} → #{new}" end)
      |> Enum.join("\n")

    message = "bump: version update\n\n#{summary}"
    Git.commit(message)

    # Tag the primary (direct) change
    case Enum.find(changes, &(&1.reason == :direct)) do
      %{app: app, new: new} ->
        tag_name = "#{app}-v#{new}"
        Git.tag(tag_name, "Release #{app} v#{new}")
        UI.info("  #{UI.green("tagged")} #{tag_name}")

      nil ->
        :ok
    end

    :ok
  end
end
