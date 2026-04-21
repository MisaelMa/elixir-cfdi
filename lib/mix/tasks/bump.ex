defmodule Mix.Tasks.Bump do
  @shortdoc "Bump version of an app and cascade to dependents (like Rush)"
  @moduledoc """
  Bumps the semver version of an app and automatically bumps all
  apps that depend on it (patch bump), cascading through the dependency graph.

  ## Usage

      mix bump <app_name> <major|minor|patch>
      mix bump <app_name> <major|minor|patch> --tag dev
      mix bump <app_name> release
      mix bump --list
      mix bump --graph <app_name>

  ## Tags (pre-release)

  Tags work like npm dist-tags. You can publish pre-release versions
  before promoting to a stable release:

      mix bump cfdi_catalogos patch --tag dev    # 4.0.16 → 4.0.17-dev.1
      mix bump cfdi_catalogos patch --tag dev    # 4.0.17-dev.1 → 4.0.17-dev.2
      mix bump cfdi_catalogos minor --tag beta   # 4.0.17-dev.2 → 4.1.0-beta.1
      mix bump cfdi_catalogos release            # 4.1.0-beta.1 → 4.1.0

  ## Options

      --dry-run    Show what would change without modifying files
      --no-cascade Only bump the specified app, skip dependents
      --tag TAG    Add a pre-release tag (dev, beta, rc, alpha, etc.)
      --list       List all apps with their current versions
      --graph      Show dependency graph for an app
  """

  use Mix.Task

  @apps_root "apps"

  @impl Mix.Task
  def run(["--list"]) do
    discover_apps()
    |> Enum.sort_by(fn {name, _path, _ver} -> name end)
    |> Enum.group_by(fn {_name, path, _ver} -> path |> Path.split() |> Enum.at(1) end)
    |> Enum.each(fn {group, apps} ->
      Mix.shell().info("\n#{IO.ANSI.bright()}#{group}/#{IO.ANSI.reset()}")

      Enum.each(apps, fn {name, _path, version} ->
        short = name |> String.replace(~r/^(cfdi_|sat_|clir_|renapo_)/, "")
        tag_display = format_version_display(version)
        Mix.shell().info("  #{String.pad_trailing(short, 20)} #{tag_display}")
      end)
    end)

    Mix.shell().info("")
  end

  def run(["--graph", app_name]) do
    apps = discover_apps()
    dep_map = build_dependency_map(apps)

    Mix.shell().info("\n#{IO.ANSI.bright()}Dependents of #{app_name}:#{IO.ANSI.reset()}")
    print_dependents_tree(app_name, dep_map, 1, MapSet.new())
    Mix.shell().info("")
  end

  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args, switches: [dry_run: :boolean, no_cascade: :boolean, tag: :string])

    case positional do
      [app_name, "release"] ->
        do_release(app_name, opts)

      [app_name, bump_type] when bump_type in ~w[major minor patch] ->
        do_bump(app_name, String.to_atom(bump_type), opts)

      _ ->
        Mix.shell().error("""
        Usage: mix bump <app_name> <major|minor|patch> [--tag TAG] [--dry-run] [--no-cascade]
               mix bump <app_name> release [--dry-run] [--no-cascade]
               mix bump --list
               mix bump --graph <app_name>
        """)
    end
  end

  defp do_release(app_name, opts) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    cascade? = not Keyword.get(opts, :no_cascade, false)
    apps = discover_apps()

    case Enum.find(apps, fn {name, _, _} -> name == app_name end) do
      nil ->
        Mix.shell().error("App '#{app_name}' not found. Run `mix bump --list` to see available apps.")

      {^app_name, path, current_version} ->
        {base, _tag, _n} = parse_version(current_version)

        if base == current_version do
          Mix.shell().info("#{app_name} is already at a stable version (#{current_version})")
          :ok
        else
          changes = [{app_name, path, current_version, base, :release}]

          changes =
            if cascade? do
              dep_map = build_dependency_map(apps)
              cascade_bumps(app_name, apps, dep_map, changes, MapSet.new([app_name]))
            else
              changes
            end

          print_and_apply(changes, dry_run?)
        end
    end
  end

  defp do_bump(app_name, bump_type, opts) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    cascade? = not Keyword.get(opts, :no_cascade, false)
    tag = Keyword.get(opts, :tag, nil)
    apps = discover_apps()

    case Enum.find(apps, fn {name, _, _} -> name == app_name end) do
      nil ->
        Mix.shell().error("App '#{app_name}' not found. Run `mix bump --list` to see available apps.")

      {^app_name, path, current_version} ->
        new_version = compute_new_version(current_version, bump_type, tag)
        label = if tag, do: :"#{bump_type}+#{tag}", else: bump_type
        changes = [{app_name, path, current_version, new_version, label}]

        changes =
          if cascade? do
            dep_map = build_dependency_map(apps)
            cascade_bumps(app_name, apps, dep_map, changes, MapSet.new([app_name]))
          else
            changes
          end

        print_and_apply(changes, dry_run?)
    end
  end

  defp print_and_apply(changes, dry_run?) do
    Mix.shell().info("")
    Mix.shell().info("#{IO.ANSI.bright()}Version changes:#{IO.ANSI.reset()}")

    Enum.each(changes, fn {name, _path, old_v, new_v, type} ->
      arrow = "#{IO.ANSI.yellow()}#{old_v}#{IO.ANSI.reset()} → #{IO.ANSI.green()}#{new_v}#{IO.ANSI.reset()}"
      Mix.shell().info("  #{String.pad_trailing(name, 25)} #{arrow}  (#{type})")
    end)

    if dry_run? do
      Mix.shell().info("\n#{IO.ANSI.cyan()}--dry-run: no files modified#{IO.ANSI.reset()}\n")
    else
      Enum.each(changes, fn {_name, path, old_v, new_v, _type} ->
        apply_version_change(path, old_v, new_v)
      end)

      Mix.shell().info("\n#{IO.ANSI.green()}#{length(changes)} app(s) updated#{IO.ANSI.reset()}\n")
    end
  end

  @doc false
  def parse_version(version) do
    case Regex.run(~r/^(\d+\.\d+\.\d+)(?:-([a-zA-Z]+)\.(\d+))?$/, version) do
      [_, base, tag, n] -> {base, tag, String.to_integer(n)}
      [_, base] -> {base, nil, 0}
      _ -> {version, nil, 0}
    end
  end

  @doc false
  def compute_new_version(current, bump_type, nil) do
    {base, _tag, _n} = parse_version(current)
    bump_base(base, bump_type)
  end

  def compute_new_version(current, bump_type, tag) do
    {base, current_tag, n} = parse_version(current)

    cond do
      # Same tag: just increment the tag number (4.0.18-dev.1 → 4.0.18-dev.2)
      current_tag == tag ->
        "#{base}-#{tag}.#{n + 1}"

      # Has a different tag: keep base, switch tag (4.0.18-dev.3 → 4.0.18-beta.1)
      current_tag != nil ->
        "#{base}-#{tag}.1"

      # No tag (clean version): bump base + add tag (4.0.17 → 4.0.18-dev.1)
      true ->
        new_base = bump_base(base, bump_type)
        "#{new_base}-#{tag}.1"
    end
  end

  @doc false
  def bump_base(base, bump_type) do
    case String.split(base, ".") |> Enum.map(&String.to_integer/1) do
      [major, minor, patch] ->
        case bump_type do
          :major -> "#{major + 1}.0.0"
          :minor -> "#{major}.#{minor + 1}.0"
          :patch -> "#{major}.#{minor}.#{patch + 1}"
        end

      _ ->
        base
    end
  end

  defp discover_apps do
    Path.wildcard(Path.join([@apps_root, "**", "mix.exs"]))
    |> Enum.filter(fn p -> p |> Path.split() |> length() == 4 end)
    |> Enum.map(fn mix_path ->
      content = File.read!(mix_path)

      app_name =
        case Regex.run(~r/app:\s+:(\w+)/, content) do
          [_, name] -> name
          _ -> nil
        end

      version =
        case Regex.run(~r/version:\s+"([^"]+)"/, content) do
          [_, v] -> v
          _ -> "0.0.0"
        end

      {app_name, Path.dirname(mix_path), version}
    end)
    |> Enum.reject(fn {name, _, _} -> is_nil(name) end)
  end

  defp build_dependency_map(apps) do
    Enum.reduce(apps, %{}, fn {app_name, path, _version}, acc ->
      mix_content = File.read!(Path.join(path, "mix.exs"))
      deps = extract_path_deps(mix_content)

      Enum.reduce(deps, acc, fn dep_name, acc2 ->
        Map.update(acc2, dep_name, [app_name], &[app_name | &1])
      end)
    end)
  end

  defp extract_path_deps(content) do
    Regex.scan(~r/\{:(\w+),\s*path:/, content)
    |> Enum.map(fn [_, name] -> name end)
  end

  defp cascade_bumps(changed_app, apps, dep_map, changes, visited) do
    dependents = Map.get(dep_map, changed_app, [])

    Enum.reduce(dependents, changes, fn dep_name, acc ->
      if MapSet.member?(visited, dep_name) do
        acc
      else
        case Enum.find(apps, fn {n, _, _} -> n == dep_name end) do
          {^dep_name, path, current_version} ->
            new_version = bump_base_only(current_version, :patch)
            new_acc = acc ++ [{dep_name, path, current_version, new_version, :patch}]
            new_visited = MapSet.put(visited, dep_name)
            cascade_bumps(dep_name, apps, dep_map, new_acc, new_visited)

          _ ->
            acc
        end
      end
    end)
  end

  # For cascaded deps: always bump the base version, strip any pre-release tag
  defp bump_base_only(version, bump_type) do
    {base, _tag, _n} = parse_version(version)
    bump_base(base, bump_type)
  end

  defp apply_version_change(app_path, old_version, new_version) do
    mix_path = Path.join(app_path, "mix.exs")
    content = File.read!(mix_path)

    updated =
      String.replace(
        content,
        ~s(version: "#{old_version}"),
        ~s(version: "#{new_version}"),
        global: false
      )

    File.write!(mix_path, updated)
  end

  defp format_version_display(version) do
    {base, tag, n} = parse_version(version)

    if tag do
      "#{base}-#{IO.ANSI.cyan()}#{tag}.#{n}#{IO.ANSI.reset()}"
    else
      version
    end
  end

  defp print_dependents_tree(app_name, dep_map, depth, visited) do
    dependents = Map.get(dep_map, app_name, [])
    indent = String.duplicate("  ", depth)

    Enum.each(dependents, fn dep ->
      if MapSet.member?(visited, dep) do
        Mix.shell().info("#{indent}└─ #{dep} (circular, skip)")
      else
        Mix.shell().info("#{indent}└─ #{dep}")
        print_dependents_tree(dep, dep_map, depth + 1, MapSet.put(visited, dep))
      end
    end)
  end
end
