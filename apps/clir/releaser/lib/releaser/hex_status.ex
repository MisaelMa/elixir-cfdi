defmodule Releaser.HexStatus do
  @moduledoc """
  Compares local app versions against published versions on Hex.

  Uses `mix hex.info <package>` to query the Hex registry.
  """

  alias Releaser.{Version, Workspace}

  @type status :: :ahead | :published | :unpublished | :prerelease

  @doc """
  Checks all apps and returns their publish status.

  Returns a list of maps with `:app`, `:local`, `:hex`, and `:status` keys.
  """
  def check(opts \\ []) do
    apps = Workspace.discover(opts)

    apps
    |> Enum.map(fn app ->
      hex_version = fetch_hex_version(app.name)
      status = compute_status(app.version, hex_version)

      %{
        app: app.name,
        local: app.version,
        hex: hex_version,
        status: status
      }
    end)
  end

  defp fetch_hex_version(app_name) do
    case System.cmd("mix", ["hex.info", app_name], stderr_to_stdout: true) do
      {output, 0} ->
        case Regex.run(~r/Releases:\s*(\S+)/, output) do
          [_, versions_str] ->
            versions_str
            |> String.split(",")
            |> List.first()
            |> String.trim()

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp compute_status(_local, nil), do: :unpublished

  defp compute_status(local, hex) do
    v = Version.parse(local)

    if Version.prerelease?(v) do
      :prerelease
    else
      case Elixir.Version.compare(local, hex) do
        :gt -> :ahead
        :eq -> :published
        :lt -> :published
      end
    end
  end
end
