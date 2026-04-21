defmodule Mix.Tasks.Releaser.Bump do
  @shortdoc "Bump version of an app with cascade, pre-release tags, and hooks"
  @moduledoc """
  Bumps the semver version of an app and cascades patch bumps to dependents.

  ## Usage

      mix releaser.bump <app> <major|minor|patch>
      mix releaser.bump <app> <major|minor|patch> --tag dev
      mix releaser.bump <app> release
      mix releaser.bump <app> 2.0.0              # explicit version
      mix releaser.bump --list
      mix releaser.bump --all patch

  ## Pre-release tags

      mix releaser.bump my_app patch --tag dev    # 4.0.17 → 4.0.18-dev.1
      mix releaser.bump my_app patch --tag dev    # 4.0.18-dev.1 → 4.0.18-dev.2
      mix releaser.bump my_app patch --tag beta   # 4.0.18-dev.2 → 4.0.18-beta.1
      mix releaser.bump my_app release            # 4.0.18-beta.1 → 4.0.18

  ## Options

      --dry-run      Show what would change without modifying files
      --no-cascade   Only bump the specified app, skip dependents
      --no-hooks     Skip pre/post hooks
      --tag TAG      Pre-release tag (dev, beta, rc, alpha, etc.)
      --build BUILD  Build metadata (e.g., 20260420)
      --list         List all apps with current versions
      --all TYPE     Bump all apps by the given type
  """

  use Mix.Task

  alias Releaser.{Version, Workspace, Cascade, FileSync, UI}

  @impl Mix.Task
  def run(["--list"]) do
    apps = Workspace.discover()

    apps
    |> Enum.group_by(fn app ->
      app.path |> Path.split() |> Enum.at(1)
    end)
    |> Enum.sort_by(fn {group, _} -> group end)
    |> Enum.each(fn {group, group_apps} ->
      UI.info("\n#{UI.bright("#{group}/")}")

      Enum.each(group_apps, fn app ->
        v = Version.parse(app.version)
        display = if Version.prerelease?(v), do: UI.cyan(app.version), else: app.version
        short = String.replace(app.name, ~r/^(\w+_)/, "")
        UI.info("  #{String.pad_trailing(short, 22)} #{display}")
      end)
    end)

    UI.info("")
  end

  def run(["--all", bump_type | rest]) do
    {opts, _, _} = OptionParser.parse(rest, switches: [dry_run: :boolean, tag: :string, build: :string, no_hooks: :boolean])
    apps = Workspace.discover()

    Enum.each(apps, fn app ->
      do_bump(app.name, parse_bump_type(bump_type), opts)
    end)
  end

  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args,
        switches: [dry_run: :boolean, no_cascade: :boolean, tag: :string, build: :string, no_hooks: :boolean]
      )

    case positional do
      [app_name, "release"] ->
        do_release(app_name, opts)

      [app_name, bump_type] when bump_type in ~w[major minor patch] ->
        do_bump(app_name, String.to_atom(bump_type), opts)

      [app_name, explicit_version] ->
        do_explicit(app_name, explicit_version, opts)

      _ ->
        UI.error("""
        Usage: mix releaser.bump <app> <major|minor|patch> [--tag TAG] [--dry-run]
               mix releaser.bump <app> release
               mix releaser.bump <app> 2.0.0
               mix releaser.bump --list
               mix releaser.bump --all patch
        """)
    end
  end

  defp do_bump(app_name, bump_type, opts) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    cascade? = not Keyword.get(opts, :no_cascade, false)
    tag = Keyword.get(opts, :tag)
    build = Keyword.get(opts, :build)
    no_hooks? = Keyword.get(opts, :no_hooks, false)

    apps = Workspace.discover()

    case Enum.find(apps, &(&1.name == app_name)) do
      nil ->
        UI.error("App '#{app_name}' not found. Run `mix releaser.bump --list`.")

      app ->
        new_version =
          app.version
          |> Version.parse()
          |> Version.bump(bump_type, tag: tag, build: build)
          |> to_string()

        changes = Cascade.plan(app_name, new_version, apps, cascade: cascade?)
        context = build_context(app, bump_type, new_version, changes, apps)

        if not no_hooks?, do: run_pre_hooks(context)
        print_and_apply(changes, dry_run?)
        if not dry_run? and not no_hooks?, do: run_post_hooks(context)
    end
  end

  defp do_release(app_name, opts) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    cascade? = not Keyword.get(opts, :no_cascade, false)
    no_hooks? = Keyword.get(opts, :no_hooks, false)
    apps = Workspace.discover()

    case Enum.find(apps, &(&1.name == app_name)) do
      nil ->
        UI.error("App '#{app_name}' not found.")

      app ->
        v = Version.parse(app.version)

        if not Version.prerelease?(v) do
          UI.info("#{app_name} is already at a stable version (#{app.version})")
        else
          new_version = v |> Version.release() |> to_string()
          changes = Cascade.plan(app_name, new_version, apps, cascade: cascade?)
          context = build_context(app, :release, new_version, changes, apps)

          if not no_hooks?, do: run_pre_hooks(context)
          print_and_apply(changes, dry_run?)
          if not dry_run? and not no_hooks?, do: run_post_hooks(context)
        end
    end
  end

  defp do_explicit(app_name, version_string, opts) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    cascade? = not Keyword.get(opts, :no_cascade, false)
    no_hooks? = Keyword.get(opts, :no_hooks, false)
    apps = Workspace.discover()

    # Validate version string
    Version.parse(version_string)

    case Enum.find(apps, &(&1.name == app_name)) do
      nil ->
        UI.error("App '#{app_name}' not found.")

      app ->
        new_version = version_string
        changes = Cascade.plan(app_name, new_version, apps, cascade: cascade?)
        context = build_context(app, :explicit, new_version, changes, apps)

        if not no_hooks?, do: run_pre_hooks(context)
        print_and_apply(changes, dry_run?)
        if not dry_run? and not no_hooks?, do: run_post_hooks(context)
    end
  end

  defp print_and_apply(changes, dry_run?) do
    config = Releaser.Config.load()

    UI.info("")
    UI.info(UI.bright("Version changes:"))

    Enum.each(changes, fn %{app: name, old: old, new: new, reason: reason} ->
      UI.info("  #{String.pad_trailing(name, 25)} #{UI.arrow(old, new)}  (#{reason})")
    end)

    if dry_run? do
      UI.info("\n#{UI.cyan("--dry-run: no files modified")}\n")
    else
      Enum.each(changes, fn %{path: path, old: old, new: new} ->
        FileSync.update_mix_version(path, old, new)
        FileSync.sync_files(path, old, new, config.version_files)
      end)

      UI.info("\n#{UI.green("#{length(changes)} app(s) updated")}\n")
    end
  end

  defp build_context(app, bump_type, new_version, changes, apps) do
    %{
      app: app.name,
      path: app.path,
      old_version: app.version,
      new_version: new_version,
      bump_type: bump_type,
      changes: changes,
      apps: apps
    }
  end

  defp run_pre_hooks(context) do
    config = Releaser.Config.load()

    Enum.each(config.hooks.pre, fn hook_mod ->
      case hook_mod.run(context) do
        :ok -> :ok
        {:error, reason} -> Mix.raise("Pre-hook #{inspect(hook_mod)} failed: #{reason}")
      end
    end)
  end

  defp run_post_hooks(context) do
    config = Releaser.Config.load()

    Enum.each(config.hooks.post, fn hook_mod ->
      case hook_mod.run(context) do
        :ok -> :ok
        {:error, reason} -> UI.error("Post-hook #{inspect(hook_mod)} failed: #{reason}")
      end
    end)
  end

  defp parse_bump_type("major"), do: :major
  defp parse_bump_type("minor"), do: :minor
  defp parse_bump_type("patch"), do: :patch
  defp parse_bump_type(other), do: Mix.raise("Invalid bump type: #{other}")
end
