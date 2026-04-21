defmodule Releaser.Cascade do
  @moduledoc """
  Plans cascade version bumps through the dependency graph.

  When a package is bumped, all packages that depend on it receive
  a patch bump automatically (like Rush in Node.js).
  """

  alias Releaser.{Graph, Version}

  @doc """
  Plans version changes for an app and its publishable dependents.

  Only cascades to apps with `publish: true`. Non-publishable apps are
  skipped — their version in Hex (if any) is already covered by `~>` constraints.

  Returns a list of `%{app: name, path: path, old: version, new: version, reason: atom}`.
  """
  def plan(app_name, new_version, apps, opts \\ []) do
    cascade? = Keyword.get(opts, :cascade, true)
    # Only cascade to publishable apps
    publishable_apps = Enum.filter(apps, & &1.publish)
    dependents_map = Graph.dependents_of(publishable_apps)
    app = Enum.find(apps, &(&1.name == app_name))

    initial = [
      %{
        app: app.name,
        path: app.path,
        old: app.version,
        new: new_version,
        reason: :direct
      }
    ]

    if cascade? do
      cascade(app_name, publishable_apps, dependents_map, initial, MapSet.new([app_name]))
    else
      initial
    end
  end

  defp cascade(changed_app, apps, dependents_map, changes, visited) do
    deps = Map.get(dependents_map, changed_app, [])

    Enum.reduce(deps, changes, fn dep_name, acc ->
      if MapSet.member?(visited, dep_name) do
        acc
      else
        case Enum.find(apps, &(&1.name == dep_name)) do
          nil ->
            acc

          dep_app ->
            v = Version.parse(dep_app.version)
            new_v = v |> Version.release() |> Version.bump(:patch) |> to_string()

            new_acc =
              acc ++
                [
                  %{
                    app: dep_name,
                    path: dep_app.path,
                    old: dep_app.version,
                    new: new_v,
                    reason: :cascade
                  }
                ]

            cascade(dep_name, apps, dependents_map, new_acc, MapSet.put(visited, dep_name))
        end
      end
    end)
  end
end
