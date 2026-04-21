defmodule Releaser.Publisher do
  @moduledoc """
  Orchestrates publishing multiple apps to Hex in topological order.

  For each app (in dependency order):
  1. Backs up the original `mix.exs`
  2. Replaces `path:` deps with their published Hex versions (`~> X.Y`)
  3. Injects `package/0` metadata if missing
  4. Runs `mix hex.publish --yes`
  5. Restores the original `mix.exs` (always, even on failure)
  """

  alias Releaser.{Graph, Version, Workspace, UI}

  @doc """
  Plans the publish order and returns a list of levels with app info.
  Does not modify anything.
  """
  def plan(opts \\ []) do
    all_apps = Workspace.discover(opts)
    # Only publishable apps participate in the publish plan
    publishable_apps = Enum.filter(all_apps, & &1.publish)
    # Filter deps to only reference other publishable apps
    publishable_names = MapSet.new(publishable_apps, & &1.name)

    publishable_apps_filtered =
      Enum.map(publishable_apps, fn app ->
        %{app | deps: Enum.filter(app.deps, &MapSet.member?(publishable_names, &1))}
      end)

    levels = Graph.topological_levels(publishable_apps_filtered)
    graph = Graph.build(publishable_apps_filtered)

    only = Keyword.get(opts, :only)

    levels =
      if only do
        # Resolve dependents (upstream) — who depends on the apps I changed?
        required = Graph.transitive_dependents(only, publishable_apps_filtered)
        Graph.filter_levels(levels, required)
      else
        levels
      end

    %{levels: levels, apps: publishable_apps_filtered, graph: graph}
  end

  @doc """
  Executes the publish flow.
  """
  def execute(opts \\ []) do
    %{levels: levels, apps: apps, graph: graph} = plan(opts)
    bump_type = Keyword.get(opts, :bump)
    org = Keyword.get(opts, :org)
    config = Releaser.Config.load()
    pkg_defaults = config.publisher.package_defaults

    published = %{}
    backups = []

    {_pub, backups} =
      Enum.reduce(levels, {published, backups}, fn {level, app_names}, {pub, bkps} ->
        UI.info("\n#{UI.bright("--- Publishing level #{level} ---")}\n")

        Enum.reduce(app_names, {pub, bkps}, fn name, {pub_acc, bkp_acc} ->
          app = Enum.find(apps, &(&1.name == name))
          mix_path = Path.join(app.path, "mix.exs")
          original = File.read!(mix_path)
          bkp_acc = [{mix_path, original} | bkp_acc]

          # 1. Bump version if requested
          new_version = maybe_bump(app.version, bump_type)
          content = replace_version(original, app.version, new_version)

          # 2. Replace path deps with hex versions
          deps = Map.get(graph, name, [])

          content =
            Enum.reduce(deps, content, fn dep, c ->
              dep_version = Map.get(pub_acc, dep, find_version(apps, dep))
              replace_path_dep(c, dep, dep_version)
            end)

          # 3. Inject package() if not present
          content = ensure_package_config(content, pkg_defaults)

          # 4. Write modified mix.exs
          File.write!(mix_path, content)

          # 5. Publish
          UI.info("Publishing #{name} v#{new_version}...")
          org_args = if org, do: ["--organization", org], else: []

          case System.cmd("mix", ["hex.publish", "--yes"] ++ org_args,
                 cd: app.path,
                 env: [{"MIX_ENV", "prod"}],
                 stderr_to_stdout: true
               ) do
            {output, 0} ->
              UI.info("  #{UI.green("#{name} v#{new_version} published!")}")
              Mix.shell().info(output)
              {Map.put(pub_acc, name, new_version), bkp_acc}

            {output, code} ->
              UI.error("Failed to publish #{name} (exit #{code}):")
              Mix.shell().info(output)
              UI.info("\n#{UI.yellow("Restoring all mix.exs files...")}")
              restore(bkp_acc)
              Mix.raise("Publish failed for #{name}. All mix.exs files have been restored.")
          end
        end)
      end)

    UI.info("\n#{UI.bright("Restoring mix.exs files to path: deps...")}")
    restore(backups)
    UI.info("#{UI.green("All done! #{length(backups)} package(s) published.")}\n")
  end

  @doc "Restores backed-up mix.exs files."
  def restore(backups) do
    Enum.each(backups, fn {path, content} -> File.write!(path, content) end)
  end

  # --- mix.exs manipulation ---

  def replace_path_dep(content, dep_name, dep_version) do
    v = Version.parse(dep_version)
    mm = Version.major_minor(v)

    Regex.replace(
      ~r/\{:#{dep_name},\s*path:\s*"[^"]*"\}/,
      content,
      "{:#{dep_name}, \"~> #{mm}\"}"
    )
  end

  def ensure_package_config(content, pkg_defaults) do
    if String.contains?(content, "package:") or String.contains?(content, "package()") do
      content
    else
      licenses = inspect(Map.get(pkg_defaults, :licenses, ["MIT"]))
      links = inspect(Map.get(pkg_defaults, :links, %{}))
      files = inspect(Map.get(pkg_defaults, :files, ~w(lib mix.exs README.md LICENSE)))

      package_fn = """

        defp package do
          [
            licenses: #{licenses},
            links: #{links},
            files: #{files}
          ]
        end
      """

      content
      |> String.replace(
        ~r/(deps:\s*deps\(\))(\s*\n)/,
        "\\1,\n      package: package()\\2"
      )
      |> String.replace(
        ~r/(  defp deps do)/,
        String.trim_trailing(package_fn) <> "\n\n\\1"
      )
    end
  end

  defp replace_version(content, old_v, new_v) when old_v == new_v, do: content

  defp replace_version(content, old_v, new_v) do
    String.replace(content, ~s(version: "#{old_v}"), ~s(version: "#{new_v}"), global: false)
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
end
