defmodule Releaser.Hooks.ChangelogHook do
  @moduledoc """
  Built-in post-hook that generates/updates CHANGELOG.md after a bump.

  Uses conventional commit prefixes to categorize changes into
  keepachangelog sections.

  Add to your config:

      releaser: [hooks: [post: [Releaser.Hooks.ChangelogHook]]]
  """

  @behaviour Releaser.Hooks.PostHook

  alias Releaser.{Changelog, UI}

  @impl true
  def run(%{new_version: new_version, path: path}) do
    config = Releaser.Config.load()
    changelog_path = Path.join(path, config.changelog.path)

    entry =
      Changelog.generate(
        version: new_version,
        path: path
      )

    Changelog.update_file(changelog_path, entry)
    UI.info("  #{UI.green("changelog")} #{changelog_path}")
    :ok
  end
end
