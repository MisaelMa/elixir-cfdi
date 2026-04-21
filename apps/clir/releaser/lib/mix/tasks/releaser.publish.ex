defmodule Mix.Tasks.Releaser.Publish do
  @shortdoc "Publish all apps to Hex in topological order"
  @moduledoc """
  Publishes all monorepo apps to Hex respecting the dependency graph.

  Before publishing each package, `path:` dependencies are replaced with
  their Hex version (`~> X.Y`). After publishing (or on failure), the
  original `mix.exs` files are restored.

  ## Usage

      mix releaser.publish                    # publish all apps
      mix releaser.publish --dry-run          # show plan without publishing
      mix releaser.publish --only app1,app2   # only these + their deps
      mix releaser.publish --bump patch       # bump before publishing
      mix releaser.publish --org myorg        # publish to a Hex org

  ## Options

      --dry-run    Show publish plan without executing
      --bump TYPE  Bump version before publishing (patch|minor|major)
      --only APPS  Comma-separated list of apps to publish
      --org ORG    Hex organization name
  """

  use Mix.Task

  alias Releaser.{Publisher, Version, UI}

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [dry_run: :boolean, only: :string, bump: :string, org: :string]
      )

    dry_run? = Keyword.get(opts, :dry_run, false)
    only = parse_only(Keyword.get(opts, :only))
    bump_type = parse_bump(Keyword.get(opts, :bump))
    org = Keyword.get(opts, :org)

    publish_opts = [only: only, bump: bump_type, org: org]
    %{levels: levels, apps: apps, graph: graph} = Publisher.plan(publish_opts)

    UI.info("\n#{UI.bright("=== Releaser Publish ===")}\n")

    Enum.each(levels, fn {level, app_names} ->
      UI.info(UI.bright("Level #{level}:"))

      Enum.each(app_names, fn name ->
        app = Enum.find(apps, &(&1.name == name))
        deps = Map.get(graph, name, [])
        dep_str = if deps == [], do: "", else: " (deps: #{Enum.join(deps, ", ")})"
        UI.info("  #{name} #{UI.yellow("v#{app.version}")}#{dep_str}")
      end)

      UI.info("")
    end)

    if dry_run? do
      UI.info("#{UI.cyan("--dry-run: nothing will be published")}\n")
      show_dry_run(levels, apps, graph, bump_type)
    else
      Publisher.execute(publish_opts)
    end
  end

  defp show_dry_run(levels, apps, graph, bump_type) do
    Enum.reduce(levels, %{}, fn {_level, app_names}, pub ->
      Enum.reduce(app_names, pub, fn name, pub_acc ->
        app = Enum.find(apps, &(&1.name == name))
        deps = Map.get(graph, name, [])

        if deps != [] do
          UI.info("#{UI.bright(name)} mix.exs changes:")

          Enum.each(deps, fn dep ->
            dep_version = Map.get(pub_acc, dep, find_version(apps, dep))
            v = Version.parse(dep_version)
            mm = Version.major_minor(v)
            UI.info("  {:#{dep}, path: \"...\"} → {:#{dep}, \"~> #{mm}\"}")
          end)

          UI.info("")
        end

        new_version = maybe_bump(app.version, bump_type)

        if bump_type do
          UI.info("  #{name}: #{UI.arrow(app.version, new_version)}")
        end

        Map.put(pub_acc, name, new_version)
      end)
    end)

    UI.info("")
  end

  defp maybe_bump(version, nil), do: version

  defp maybe_bump(version, bump_type) do
    version |> Version.parse() |> Version.release() |> Version.bump(bump_type) |> to_string()
  end

  defp find_version(apps, name) do
    case Enum.find(apps, &(&1.name == name)) do
      %{version: v} -> v
      nil -> "0.0.0"
    end
  end

  defp parse_only(nil), do: nil
  defp parse_only(str), do: str |> String.split(",") |> Enum.map(&String.trim/1)

  defp parse_bump(nil), do: nil
  defp parse_bump("major"), do: :major
  defp parse_bump("minor"), do: :minor
  defp parse_bump("patch"), do: :patch
  defp parse_bump(other), do: Mix.raise("Invalid bump type: #{other}")
end
