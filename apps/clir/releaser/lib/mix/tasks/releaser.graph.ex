defmodule Mix.Tasks.Releaser.Graph do
  @shortdoc "Show dependency graph of monorepo apps"
  @moduledoc """
  Displays the dependency graph of all apps in the workspace.

  ## Usage

      mix releaser.graph              # full graph with levels
      mix releaser.graph <app>        # show dependents of an app
  """

  use Mix.Task

  alias Releaser.{Graph, Workspace, UI}

  @impl Mix.Task
  def run([]) do
    apps = Workspace.discover()
    levels = Graph.topological_levels(apps)
    graph = Graph.build(apps)
    total_levels = length(levels)

    UI.info("\n#{UI.bright("╔══════════════════════════════════════════════════╗")}")
    UI.info("#{UI.bright("║           Dependency Graph                       ║")}")
    UI.info("#{UI.bright("╚══════════════════════════════════════════════════╝")}\n")

    Enum.each(levels, fn {level, app_names} ->
      label =
        case level do
          0 -> "Level 0  (no internal deps)"
          _ -> "Level #{level}"
        end

      UI.info(UI.cyan("┌── #{label} ──┐"))
      UI.info(UI.cyan("│"))

      Enum.each(app_names, fn name ->
        app = Enum.find(apps, &(&1.name == name))
        deps = Map.get(graph, name, [])

        UI.info("#{UI.cyan("│")}   #{UI.green(name)} #{UI.yellow("v#{app.version}")}")

        if deps != [] do
          dep_str = Enum.map(deps, &UI.yellow(&1)) |> Enum.join(", ")
          UI.info("#{UI.cyan("│")}   #{UI.dim("└─ depends on: #{dep_str}")}")
        end
      end)

      UI.info(UI.cyan("│"))

      if level < total_levels - 1 do
        UI.info("#{UI.cyan("│")}       #{UI.bright("▼")}")
        UI.info(UI.cyan("│"))
      end
    end)

    UI.info(UI.cyan("└── end ──┘"))

    total = Enum.reduce(levels, 0, fn {_, names}, acc -> acc + length(names) end)
    with_deps = Enum.count(apps, &(&1.deps != []))

    UI.info("\n#{UI.bright("Summary:")}")
    UI.info("  Total apps:         #{total}")
    UI.info("  Levels:             #{total_levels}")
    UI.info("  Apps with path deps: #{with_deps}")
    UI.info("  Publish order:      level 0 → level #{total_levels - 1}")
    UI.info("")
  end

  def run([app_name]) do
    apps = Workspace.discover()
    dependents_map = Graph.dependents_of(apps)

    UI.info("\n#{UI.bright("Dependents of #{app_name}:")}")
    print_tree(app_name, dependents_map, 1, MapSet.new())
    UI.info("")
  end

  def run(_) do
    UI.error("Usage: mix releaser.graph [app_name]")
  end

  defp print_tree(app_name, dep_map, depth, visited) do
    dependents = Map.get(dep_map, app_name, [])
    indent = String.duplicate("  ", depth)

    Enum.each(dependents, fn dep ->
      if MapSet.member?(visited, dep) do
        UI.info("#{indent}└─ #{dep} (circular, skip)")
      else
        UI.info("#{indent}└─ #{dep}")
        print_tree(dep, dep_map, depth + 1, MapSet.put(visited, dep))
      end
    end)
  end
end
