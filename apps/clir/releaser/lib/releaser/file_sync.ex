defmodule Releaser.FileSync do
  @moduledoc """
  Syncs version numbers across multiple files.

  Besides `mix.exs` (which is always updated), you can configure additional
  files like README.md, Dockerfile, or any file containing a version string.

  ## Configuration

      releaser: [
        version_files: [
          {"README.md", ~r/version "(\d+\.\d+\.\d+)"/},
          {"Dockerfile", ~r/ARG VERSION=(\S+)/}
        ]
      ]
  """

  @doc """
  Updates the version in `mix.exs` for the given app path.
  """
  def update_mix_version(app_path, old_version, new_version) do
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

  @doc """
  Syncs version in all configured additional files for the given app.

  `files` is a list of `{path_or_glob, regex}` tuples where the regex
  must contain a capture group matching the version string to replace.
  """
  def sync_files(app_path, old_version, new_version, files) do
    Enum.each(files, fn {pattern, regex} ->
      resolved =
        if String.contains?(pattern, "*") do
          Path.wildcard(pattern)
        else
          path = Path.join(app_path, pattern)
          if File.exists?(path), do: [path], else: []
        end

      Enum.each(resolved, fn file_path ->
        content = File.read!(file_path)

        updated =
          Regex.replace(regex, content, fn full_match, _captured ->
            String.replace(full_match, old_version, new_version)
          end)

        if updated != content do
          File.write!(file_path, updated)
        end
      end)
    end)
  end
end
