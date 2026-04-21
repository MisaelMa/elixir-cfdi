defmodule Releaser.App do
  @moduledoc """
  Struct representing a discovered app in the workspace.

  The `publish` field indicates whether this app should be published to Hex.
  Set `releaser: [publish: true]` in the app's `mix.exs` to mark it as publishable.
  """
  defstruct [:name, :path, :version, :deps, publish: false]

  @type t :: %__MODULE__{
          name: String.t(),
          path: String.t(),
          version: String.t(),
          deps: [String.t()],
          publish: boolean()
        }
end

defmodule Releaser.Workspace do
  @moduledoc """
  Discovers apps in a poncho/umbrella project.

  Scans the configured `apps_root` directory for Mix projects and extracts
  their name, version, and internal (path-based) dependencies.

  Supports both flat (`apps/foo/mix.exs`) and nested (`apps/group/foo/mix.exs`) layouts.
  """

  alias Releaser.App

  @doc """
  Discovers all apps in the workspace.

  Returns a list of `%Releaser.App{}` structs sorted by name.
  """
  def discover(opts \\ []) do
    apps_root = Keyword.get(opts, :apps_root, Releaser.Config.load().apps_root)

    mix_files = Path.wildcard(Path.join([apps_root, "**", "mix.exs"]))

    apps =
      mix_files
      |> Enum.reject(fn p ->
        # Skip the root mix.exs and _build/deps paths
        String.contains?(p, "_build") or String.contains?(p, "/deps/")
      end)
      |> Enum.map(&parse_mix_file/1)
      |> Enum.reject(&is_nil/1)

    # Resolve: only keep path deps that refer to other discovered apps
    app_names = MapSet.new(apps, & &1.name)

    apps
    |> Enum.map(fn app ->
      %{app | deps: Enum.filter(app.deps, &MapSet.member?(app_names, &1))}
    end)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Finds a single app by name. Returns `nil` if not found.
  """
  def find(name, opts \\ []) when is_binary(name) do
    discover(opts) |> Enum.find(&(&1.name == name))
  end

  defp parse_mix_file(mix_path) do
    content = File.read!(mix_path)

    name =
      case Regex.run(~r/app:\s+:(\w+)/, content) do
        [_, n] -> n
        _ -> nil
      end

    version =
      case Regex.run(~r/version:\s+"([^"]+)"/, content) do
        [_, v] -> v
        _ -> "0.0.0"
      end

    path_deps =
      Regex.scan(~r/\{:(\w+),\s*path:/, content)
      |> Enum.map(fn [_, dep_name] -> dep_name end)

    umbrella_deps =
      Regex.scan(~r/\{:(\w+),\s*in_umbrella:\s*true\}/, content)
      |> Enum.map(fn [_, dep_name] -> dep_name end)

    path_deps = Enum.uniq(path_deps ++ umbrella_deps)

    publish? = Regex.match?(~r/publish:\s*true/, content)

    if name do
      %App{
        name: name,
        path: Path.dirname(mix_path),
        version: version,
        deps: path_deps,
        publish: publish?
      }
    end
  end
end
