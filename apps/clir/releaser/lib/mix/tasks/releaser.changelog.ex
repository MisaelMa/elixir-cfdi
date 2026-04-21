defmodule Mix.Tasks.Releaser.Changelog do
  @shortdoc "Generate changelog from git commits"
  @moduledoc """
  Generates a changelog entry from git commits using conventional commit prefixes.

  ## Usage

      mix releaser.changelog                  # generate for all apps
      mix releaser.changelog <app>            # generate for one app
      mix releaser.changelog --from v1.0.0    # from a specific git ref

  ## Options

      --from REF     Start from a specific git ref (default: latest tag)
      --to REF       End at a specific git ref (default: HEAD)
      --dry-run      Show changelog without writing to file
  """

  use Mix.Task

  alias Releaser.{Changelog, Workspace, UI}

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args, switches: [from: :string, to: :string, dry_run: :boolean])

    dry_run? = Keyword.get(opts, :dry_run, false)
    from = Keyword.get(opts, :from)
    to = Keyword.get(opts, :to, "HEAD")

    case positional do
      [app_name] ->
        generate_for_app(app_name, from, to, dry_run?)

      [] ->
        generate_all(from, to, dry_run?)

      _ ->
        UI.error("Usage: mix releaser.changelog [app_name] [--from REF] [--dry-run]")
    end
  end

  defp generate_for_app(app_name, from, to, dry_run?) do
    app = Workspace.find(app_name)

    if is_nil(app) do
      UI.error("App '#{app_name}' not found.")
    else
      entry = Changelog.generate(version: app.version, from: from, to: to, path: app.path)

      if dry_run? do
        UI.info("\n#{UI.bright("Changelog for #{app_name}:")}\n")
        UI.info(entry)
        UI.info("\n#{UI.cyan("--dry-run: no files written")}\n")
      else
        config = Releaser.Config.load()
        path = Path.join(app.path, config.changelog.path)
        Changelog.update_file(path, entry)
        UI.info("#{UI.green("Updated")} #{path}")
      end
    end
  end

  defp generate_all(from, to, dry_run?) do
    apps = Workspace.discover()

    Enum.each(apps, fn app ->
      entry = Changelog.generate(version: app.version, from: from, to: to, path: app.path)

      if dry_run? do
        UI.info("\n#{UI.bright("--- #{app.name} ---")}")
        UI.info(entry)
      else
        config = Releaser.Config.load()
        path = Path.join(app.path, config.changelog.path)
        Changelog.update_file(path, entry)
        UI.info("#{UI.green("Updated")} #{path}")
      end
    end)

    if dry_run?, do: UI.info("\n#{UI.cyan("--dry-run: no files written")}\n")
  end
end
