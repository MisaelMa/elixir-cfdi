defmodule Releaser.Graph do
  @moduledoc """
  Dependency graph building and topological sorting for monorepo apps.

  Builds a directed graph from internal `path:` dependencies and provides
  topological ordering for correct publish order, dependency resolution,
  and cascade planning.
  """

  alias Releaser.App

  @doc """
  Builds a dependency graph from a list of apps.

  Returns a map of `%{app_name => [dependency_names]}`.
  """
  def build(apps) when is_list(apps) do
    Map.new(apps, fn %App{name: name, deps: deps} -> {name, deps} end)
  end

  @doc """
  Returns a map of `%{app_name => [dependent_names]}` (reverse graph).

  For each app, lists which apps depend on it.
  """
  def dependents_of(apps) when is_list(apps) do
    Enum.reduce(apps, %{}, fn %App{name: name, deps: deps}, acc ->
      Enum.reduce(deps, acc, fn dep, acc2 ->
        Map.update(acc2, dep, [name], &[name | &1])
      end)
    end)
  end

  @doc """
  Computes topological levels using Kahn's algorithm.

  Returns `[{level, [app_names]}]` where level 0 has no internal deps,
  level 1 depends only on level 0, etc.
  """
  def topological_levels(apps) when is_list(apps) do
    graph = build(apps)
    all_names = MapSet.new(apps, & &1.name)
    do_levels(all_names, graph, 0, [])
  end

  defp do_levels(remaining, graph, level, acc) do
    if MapSet.size(remaining) == 0 do
      Enum.reverse(acc)
    else
      placed = placed_set(acc)

      ready =
        remaining
        |> MapSet.to_list()
        |> Enum.filter(fn name ->
          deps = Map.get(graph, name, [])
          Enum.all?(deps, &MapSet.member?(placed, &1))
        end)
        |> Enum.sort()

      if ready == [] do
        {:error, :circular_dependency, MapSet.to_list(remaining)}
      else
        new_remaining = MapSet.difference(remaining, MapSet.new(ready))
        do_levels(new_remaining, graph, level + 1, [{level, ready} | acc])
      end
    end
  end

  defp placed_set(levels) do
    levels
    |> Enum.flat_map(fn {_level, names} -> names end)
    |> MapSet.new()
  end

  @doc """
  Resolves transitive dependencies for a list of app names.

  Returns a MapSet of all apps that need to be included (the requested
  apps plus all their transitive dependencies).
  """
  def transitive_deps(app_names, graph) when is_list(app_names) and is_map(graph) do
    Enum.reduce(app_names, MapSet.new(), fn name, acc ->
      collect_transitive(name, graph, acc)
    end)
  end

  defp collect_transitive(name, graph, visited) do
    if MapSet.member?(visited, name) do
      visited
    else
      visited = MapSet.put(visited, name)

      Map.get(graph, name, [])
      |> Enum.reduce(visited, fn dep, acc -> collect_transitive(dep, graph, acc) end)
    end
  end

  @doc """
  Resolves transitive dependents for a list of app names (reverse direction).

  Given an app, returns all apps that depend on it recursively (upstream).
  For example, if `cfdi_xml` depends on `cfdi_csd`, then `cfdi_xml` is a
  transitive dependent of `cfdi_csd`.

  This is the inverse of `transitive_deps/2`.
  """
  def transitive_dependents(app_names, apps) when is_list(app_names) and is_list(apps) do
    dep_map = dependents_of(apps)

    Enum.reduce(app_names, MapSet.new(app_names), fn name, acc ->
      collect_dependents(name, dep_map, acc)
    end)
  end

  defp collect_dependents(name, dep_map, visited) do
    dependents = Map.get(dep_map, name, [])

    Enum.reduce(dependents, visited, fn dep, acc ->
      if MapSet.member?(acc, dep) do
        acc
      else
        acc
        |> MapSet.put(dep)
        |> then(&collect_dependents(dep, dep_map, &1))
      end
    end)
  end

  @doc """
  Filters topological levels to only include the specified apps.
  Removes empty levels.
  """
  def filter_levels(levels, required_apps) when is_list(levels) do
    levels
    |> Enum.map(fn {level, names} ->
      {level, Enum.filter(names, &MapSet.member?(required_apps, &1))}
    end)
    |> Enum.reject(fn {_level, names} -> names == [] end)
  end
end
