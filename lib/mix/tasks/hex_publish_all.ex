defmodule Mix.Tasks.Hex.PublishAll do
  @shortdoc "Publish all umbrella apps to Hex in topological order"
  @moduledoc """
  Publica todos los apps del umbrella a Hex respetando el grafo de dependencias.
  Los paquetes sin dependencias internas se publican primero (nivel 0), luego
  los que dependen de ellos (nivel 1), y así sucesivamente.

  Antes de publicar cada paquete, las dependencias `path:` se reemplazan
  temporalmente por su versión de Hex (`~> X.Y`). Al terminar (o si falla),
  los `mix.exs` originales se restauran automáticamente.

  ## Comandos

      mix hex.publish_all                    # publicar todos los apps
      mix hex.publish_all --dry-run          # ver plan sin publicar nada
      mix hex.publish_all --graph            # ver grafo visual de dependencias
      mix hex.publish_all --only cfdi_xml    # publicar solo cfdi_xml (y sus deps)
      mix hex.publish_all --bump patch       # bump versión antes de publicar
      mix hex.publish_all --org myorg        # publicar a una organización de Hex

  ## Opciones

      --dry-run    Muestra el orden de publicación y los cambios en mix.exs
                   sin modificar archivos ni publicar nada
      --graph      Muestra el grafo visual de dependencias internas con árbol ASCII
      --bump TYPE  Bump de versión antes de publicar (patch | minor | major)
      --only APPS  Lista de apps separados por coma. Publica solo esos apps
                   más sus dependencias transitivas en el orden correcto
      --org ORG    Publica a una organización de Hex

  ## Flujo de publicación

  El flujo que ejecuta para cada paquete (en orden topológico):

    1. Backup del `mix.exs` original
    2. Bump de versión si se pasó `--bump`
    3. Reemplazo de deps `path:` → `~> X.Y` (versión publicada del dep)
    4. Inyección de `package/0` con licencia y links si no existe
    5. `mix hex.publish --yes`
    6. Restauración del `mix.exs` original (siempre, incluso si falla)

  ## Ejemplos

  ### Ver el grafo de dependencias

      $ mix hex.publish_all --graph

      ┌─────────────────────────────────────────────┐
      │           CFDI Umbrella - Dep Graph          │
      ├─────────────────────────────────────────────┤
      │                                             │
      │  Level 0 (sin deps internas):               │
      │    cfdi_catalogos, cfdi_complementos, ...    │
      │    clir_openssl, saxon_he, ...               │
      │        │              │                      │
      │  Level 1:             │                      │
      │    cfdi_csd ──────────┘                      │
      │        │                                     │
      │  Level 2:                                    │
      │    cfdi_xml ─── sat_auth                     │
      │                    │                         │
      │  Level 3:          │                         │
      │    cfdi_cancelacion ─── cfdi_descarga        │
      │                                             │
      └─────────────────────────────────────────────┘

  ### Publicar todo con bump patch

      $ mix hex.publish_all --bump patch

  ### Solo publicar cfdi_xml (automáticamente incluye sus deps)

      $ mix hex.publish_all --only cfdi_xml --bump patch

      Esto publicará en orden:
        1. clir_openssl, cfdi_transform, cfdi_complementos, cfdi_catalogos,
           cfdi_xsd, saxon_he  (nivel 0, sin deps)
        2. cfdi_csd             (nivel 1, depende de clir_openssl)
        3. cfdi_xml             (nivel 2, depende de todos los anteriores)

  ## Prerequisitos

  - Cada app debe tener `description` en su `mix.exs`
  - Debes estar autenticado en Hex: `mix hex.user auth`
  - El task inyecta `package/0` automáticamente si no existe

  ## Relación con `mix bump`

  Puedes usar `mix bump` para cambiar versiones antes de publicar,
  o usar `--bump` en este task para hacerlo en un solo paso:

      # Opción A: bump manual + publicar
      mix bump cfdi_catalogos patch
      mix hex.publish_all

      # Opción B: todo junto
      mix hex.publish_all --bump patch
  """

  use Mix.Task

  @apps_root "apps"

  @impl Mix.Task
  def run(args) do
    {opts, _positional, _} =
      OptionParser.parse(args,
        switches: [dry_run: :boolean, only: :string, bump: :string, org: :string, graph: :boolean]
      )

    apps = discover_apps()
    graph = build_internal_deps_graph(apps)
    levels = topological_levels(apps, graph)

    if Keyword.get(opts, :graph, false) do
      show_visual_graph(levels, apps, graph)
      :ok
    else
      do_publish_or_dry_run(args, opts, apps, graph, levels)
    end
  end

  defp do_publish_or_dry_run(_args, opts, apps, graph, levels) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    only = parse_only(Keyword.get(opts, :only))
    bump_type = parse_bump(Keyword.get(opts, :bump))
    org = Keyword.get(opts, :org)

    # If --only, filter to only requested apps + their transitive deps
    levels =
      if only do
        required = resolve_required_apps(only, graph)
        filter_levels(levels, required)
      else
        levels
      end

    info("\n#{bright()}=== Hex Publish All ==#{reset()}\n")

    # Show the publish plan
    Enum.each(levels, fn {level, app_names} ->
      info("#{bright()}Level #{level}:#{reset()}")

      Enum.each(app_names, fn name ->
        {_, _path, version} = find_app(apps, name)
        deps = Map.get(graph, name, [])
        dep_str = if deps == [], do: "", else: " (deps: #{Enum.join(deps, ", ")})"
        info("  #{name} #{yellow()}v#{version}#{reset()}#{dep_str}")
      end)

      info("")
    end)

    if dry_run? do
      info("#{cyan()}--dry-run: nothing will be published#{reset()}\n")
      show_dry_run_detail(levels, apps, graph, bump_type)
    else
      publish_all(levels, apps, graph, bump_type, org)
    end
  end

  # --- Discovery & Graph ---

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

  defp build_internal_deps_graph(apps) do
    app_names = MapSet.new(apps, fn {name, _, _} -> name end)

    Map.new(apps, fn {app_name, path, _version} ->
      mix_content = File.read!(Path.join(path, "mix.exs"))

      internal_deps =
        Regex.scan(~r/\{:(\w+),\s*path:/, mix_content)
        |> Enum.map(fn [_, name] -> name end)
        |> Enum.filter(&MapSet.member?(app_names, &1))

      {app_name, internal_deps}
    end)
  end

  defp topological_levels(apps, graph) do
    all_names = Enum.map(apps, fn {name, _, _} -> name end) |> MapSet.new()
    do_levels(all_names, graph, 0, [])
  end

  defp do_levels(remaining, graph, level, acc) do
    if MapSet.size(remaining) == 0 do
      Enum.reverse(acc)
    else
      placed = placed_apps(acc)

      ready =
        remaining
        |> MapSet.to_list()
        |> Enum.filter(fn name ->
          deps = Map.get(graph, name, [])
          Enum.all?(deps, &MapSet.member?(placed, &1))
        end)
        |> Enum.sort()

      if ready == [] do
        error("Circular dependency detected among: #{inspect(MapSet.to_list(remaining))}")
        Enum.reverse(acc)
      else
        new_remaining = MapSet.difference(remaining, MapSet.new(ready))
        do_levels(new_remaining, graph, level + 1, [{level, ready} | acc])
      end
    end
  end

  defp placed_apps(levels) do
    levels
    |> Enum.flat_map(fn {_level, names} -> names end)
    |> MapSet.new()
  end

  # --- Resolve --only transitive deps ---

  defp resolve_required_apps(only_list, graph) do
    Enum.reduce(only_list, MapSet.new(), fn app, acc ->
      collect_deps(app, graph, acc)
    end)
  end

  defp collect_deps(app, graph, visited) do
    if MapSet.member?(visited, app) do
      visited
    else
      visited = MapSet.put(visited, app)

      Map.get(graph, app, [])
      |> Enum.reduce(visited, fn dep, acc -> collect_deps(dep, graph, acc) end)
    end
  end

  defp filter_levels(levels, required) do
    levels
    |> Enum.map(fn {level, names} ->
      {level, Enum.filter(names, &MapSet.member?(required, &1))}
    end)
    |> Enum.reject(fn {_level, names} -> names == [] end)
  end

  # --- Visual Graph ---

  defp show_visual_graph(levels, apps, graph) do
    info("\n#{bright()}╔══════════════════════════════════════════════════╗#{reset()}")
    info("#{bright()}║        CFDI Umbrella — Dependency Graph          ║#{reset()}")
    info("#{bright()}╚══════════════════════════════════════════════════╝#{reset()}\n")

    total_levels = length(levels)

    Enum.each(levels, fn {level, app_names} ->
      # Level header
      label =
        case level do
          0 -> "Level 0  (sin dependencias internas)"
          _ -> "Level #{level}"
        end

      info("#{bright()}#{cyan()}┌── #{label} ──┐#{reset()}")
      info("#{cyan()}│#{reset()}")

      # Group apps by prefix for cleaner display
      grouped = group_by_prefix(app_names)

      Enum.each(grouped, fn {_prefix, names} ->
        Enum.each(names, fn name ->
          {_, _path, version} = find_app(apps, name)
          deps = Map.get(graph, name, [])

          version_str = "#{yellow()}v#{version}#{reset()}"

          if deps == [] do
            info("#{cyan()}│#{reset()}   #{green()}#{name}#{reset()} #{version_str}")
          else
            dep_arrows =
              deps
              |> Enum.map(fn d -> "#{yellow()}#{d}#{reset()}" end)
              |> Enum.join(", ")

            info("#{cyan()}│#{reset()}   #{green()}#{name}#{reset()} #{version_str}")
            info("#{cyan()}│#{reset()}   #{dim()}└─ depends on: #{dep_arrows}#{reset()}")
          end
        end)
      end)

      info("#{cyan()}│#{reset()}")

      if level < total_levels - 1 do
        info("#{cyan()}│#{reset()}       #{bright()}▼#{reset()}")
        info("#{cyan()}│#{reset()}")
      end
    end)

    info("#{bright()}#{cyan()}└── end ──┘#{reset()}")

    # Summary
    total_apps = Enum.reduce(levels, 0, fn {_, names}, acc -> acc + length(names) end)
    info("\n#{bright()}Resumen:#{reset()}")
    info("  Total apps:          #{total_apps}")
    info("  Niveles:             #{total_levels}")
    info("  Apps con deps path:  #{count_apps_with_deps(levels, graph)}")
    info("  Orden de publicación: nivel 0 → nivel #{total_levels - 1}")
    info("")
  end

  defp group_by_prefix(app_names) do
    app_names
    |> Enum.group_by(fn name ->
      cond do
        String.starts_with?(name, "cfdi_") -> "cfdi"
        String.starts_with?(name, "sat_") -> "sat"
        String.starts_with?(name, "clir_") -> "clir"
        String.starts_with?(name, "renapo_") -> "renapo"
        true -> "other"
      end
    end)
    |> Enum.sort_by(fn {prefix, _} -> prefix end)
  end

  defp count_apps_with_deps(levels, graph) do
    levels
    |> Enum.flat_map(fn {_, names} -> names end)
    |> Enum.count(fn name -> Map.get(graph, name, []) != [] end)
  end

  defp dim, do: IO.ANSI.faint()

  # --- Dry Run Detail ---

  defp show_dry_run_detail(levels, apps, graph, bump_type) do
    published = %{}

    Enum.reduce(levels, published, fn {_level, app_names}, pub ->
      Enum.reduce(app_names, pub, fn name, pub_acc ->
        {_, _path, version} = find_app(apps, name)
        new_version = maybe_bump(version, bump_type)
        deps = Map.get(graph, name, [])

        if deps != [] do
          info("#{bright()}#{name}#{reset()} mix.exs changes:")

          Enum.each(deps, fn dep ->
            dep_version = Map.get(pub_acc, dep, find_version(apps, dep))
            major_minor = major_minor(dep_version)
            info("  {:#{dep}, path: \"...\"} → {:#{dep}, \"~> #{major_minor}\"}")
          end)

          info("")
        end

        if bump_type do
          info("  #{name}: #{yellow()}#{version}#{reset()} → #{green()}#{new_version}#{reset()}")
        end

        Map.put(pub_acc, name, new_version)
      end)
    end)

    info("")
  end

  # --- Publish ---

  defp publish_all(levels, apps, graph, bump_type, org) do
    published = %{}
    backups = []

    {_pub, backups} =
      Enum.reduce(levels, {published, backups}, fn {level, app_names}, {pub, bkps} ->
        info("#{bright()}--- Publishing level #{level} ---#{reset()}\n")

        Enum.reduce(app_names, {pub, bkps}, fn name, {pub_acc, bkp_acc} ->
          {_, path, version} = find_app(apps, name)
          mix_path = Path.join(path, "mix.exs")
          original = File.read!(mix_path)
          bkp_acc = [{mix_path, original} | bkp_acc]

          # 1. Bump version if requested
          new_version = maybe_bump(version, bump_type)
          content = replace_version(original, version, new_version)

          # 2. Replace path deps with hex versions
          deps = Map.get(graph, name, [])

          content =
            Enum.reduce(deps, content, fn dep, c ->
              dep_version = Map.get(pub_acc, dep, find_version(apps, dep))
              replace_path_dep(c, dep, dep_version)
            end)

          # 3. Inject package() if not present
          content = ensure_package_config(content)

          # 4. Write modified mix.exs
          File.write!(mix_path, content)

          # 5. Publish
          info("Publishing #{name} v#{new_version}...")

          org_args = if org, do: ["--organization", org], else: []

          case System.cmd("mix", ["hex.publish", "--yes"] ++ org_args,
                 cd: path,
                 env: [{"MIX_ENV", "prod"}],
                 stderr_to_stdout: true
               ) do
            {output, 0} ->
              info("#{green()}#{name} v#{new_version} published!#{reset()}")
              Mix.shell().info(output)
              {Map.put(pub_acc, name, new_version), bkp_acc}

            {output, code} ->
              error("Failed to publish #{name} (exit #{code}):")
              Mix.shell().info(output)
              info("\n#{yellow()}Restoring all mix.exs files...#{reset()}")
              restore_backups(bkp_acc)
              Mix.raise("Publish failed for #{name}. All mix.exs files have been restored.")
          end
        end)
      end)

    # Restore all mix.exs to path: deps for local dev
    info("\n#{bright()}Restoring mix.exs files to path: deps...#{reset()}")
    restore_backups(backups)
    info("#{green()}All done! #{length(backups)} package(s) published.#{reset()}\n")
  end

  # --- mix.exs Manipulation ---

  defp replace_version(content, old_version, new_version) do
    if old_version == new_version do
      content
    else
      String.replace(
        content,
        ~s(version: "#{old_version}"),
        ~s(version: "#{new_version}"),
        global: false
      )
    end
  end

  defp replace_path_dep(content, dep_name, dep_version) do
    major_minor = major_minor(dep_version)
    # Match {:dep_name, path: "..."} and replace with {:dep_name, "~> X.Y"}
    Regex.replace(
      ~r/\{:#{dep_name},\s*path:\s*"[^"]*"\}/,
      content,
      "{:#{dep_name}, \"~> #{major_minor}\"}"
    )
  end

  defp ensure_package_config(content) do
    if String.contains?(content, "package:") or String.contains?(content, "package()") do
      content
    else
      # Inject package: package() into project/0 and add defp package
      content
      |> String.replace(
        ~r/(deps:\s*deps\(\))(\s*\n)/,
        "\\1,\n      package: package()\\2"
      )
      |> inject_package_function()
    end
  end

  defp inject_package_function(content) do
    # Insert defp package() before the last `end` of the module
    package_fn = """

      defp package do
        [
          licenses: ["MIT"],
          links: %{"GitHub" => "https://github.com/MisaelMa/cfdi"},
          files: ~w(lib mix.exs README.md LICENSE)
        ]
      end
    """

    # Insert before `defp deps`
    String.replace(
      content,
      ~r/(  defp deps do)/,
      String.trim_trailing(package_fn) <> "\n\n\\1"
    )
  end

  # --- Backup / Restore ---

  defp restore_backups(backups) do
    Enum.each(backups, fn {path, content} ->
      File.write!(path, content)
    end)
  end

  # --- Version Helpers ---

  defp maybe_bump(version, nil), do: version

  defp maybe_bump(version, bump_type) do
    case String.split(strip_prerelease(version), ".") |> Enum.map(&String.to_integer/1) do
      [major, minor, patch] ->
        case bump_type do
          :major -> "#{major + 1}.0.0"
          :minor -> "#{major}.#{minor + 1}.0"
          :patch -> "#{major}.#{minor}.#{patch + 1}"
        end

      _ ->
        version
    end
  end

  defp strip_prerelease(version) do
    version |> String.split("-") |> hd()
  end

  defp major_minor(version) do
    case String.split(strip_prerelease(version), ".") |> Enum.map(&String.to_integer/1) do
      [major, minor, _patch] -> "#{major}.#{minor}"
      _ -> version
    end
  end

  # --- Lookup Helpers ---

  defp find_app(apps, name) do
    Enum.find(apps, fn {n, _, _} -> n == name end)
  end

  defp find_version(apps, name) do
    case find_app(apps, name) do
      {_, _, v} -> v
      nil -> "0.0.0"
    end
  end

  defp parse_only(nil), do: nil

  defp parse_only(str) do
    str |> String.split(",") |> Enum.map(&String.trim/1)
  end

  defp parse_bump(nil), do: nil
  defp parse_bump("major"), do: :major
  defp parse_bump("minor"), do: :minor
  defp parse_bump("patch"), do: :patch
  defp parse_bump(other), do: Mix.raise("Invalid bump type: #{other}. Use major, minor, or patch.")

  # --- Output Helpers ---

  defp info(msg), do: Mix.shell().info(msg)
  defp error(msg), do: Mix.shell().error(msg)
  defp bright, do: IO.ANSI.bright()
  defp reset, do: IO.ANSI.reset()
  defp yellow, do: IO.ANSI.yellow()
  defp green, do: IO.ANSI.green()
  defp cyan, do: IO.ANSI.cyan()
end
