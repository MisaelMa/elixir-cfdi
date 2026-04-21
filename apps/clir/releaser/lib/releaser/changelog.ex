defmodule Releaser.Changelog do
  @moduledoc """
  Generates changelogs from git commits using conventional commit prefixes.

  Parses commit messages for prefixes like `feat:`, `fix:`, `refactor:` and
  maps them to keepachangelog sections (Added, Fixed, Changed, etc.).

  ## Commit format

  Commits should follow conventional commits:

      feat: add support for CartaPorte 3.1
      fix: correct encoding issue in XML builder
      refactor: extract version parsing to struct
      breaking: remove deprecated cer/key modules

  ## Configuration

      releaser: [
        changelog: [
          anchors: %{
            "feat" => "Added",
            "fix" => "Fixed",
            "refactor" => "Changed",
            "breaking" => "Breaking Changes"
          }
        ]
      ]
  """

  alias Releaser.Git

  @doc """
  Generates a changelog string from git commits.

  ## Options

  - `:from` — Git ref to start from (default: latest tag)
  - `:to` — Git ref to end at (default: `"HEAD"`)
  - `:path` — Scope commits to a directory path
  - `:version` — Version string for the heading
  - `:anchors` — Map of prefix → section name (overrides config)
  """
  def generate(opts \\ []) do
    config = Releaser.Config.load()
    anchors = Keyword.get(opts, :anchors, config.changelog.anchors)
    version = Keyword.get(opts, :version, "Unreleased")
    from = Keyword.get(opts, :from, Git.latest_tag())
    to = Keyword.get(opts, :to, "HEAD")
    path = Keyword.get(opts, :path)

    commits = Git.log(from: from, to: to, path: path)

    sections =
      commits
      |> Enum.map(&categorize(&1, anchors))
      |> Enum.reject(fn {section, _} -> is_nil(section) end)
      |> Enum.group_by(fn {section, _} -> section end, fn {_, msg} -> msg end)

    format_keepachangelog(version, sections, anchors)
  end

  @doc """
  Reads existing CHANGELOG.md and prepends a new version entry.

  If the file doesn't exist, creates it with the standard header.
  """
  def update_file(changelog_path, new_entry) do
    if File.exists?(changelog_path) do
      content = File.read!(changelog_path)

      # Insert after the "# Changelog" header and first blank line
      updated =
        case String.split(content, "\n## ", parts: 2) do
          [header, rest] ->
            "#{String.trim_trailing(header)}\n\n#{new_entry}\n\n## #{rest}"

          [_only_header] ->
            "#{String.trim_trailing(content)}\n\n#{new_entry}\n"
        end

      File.write!(changelog_path, updated)
    else
      header = """
      # Changelog

      All notable changes to this project will be documented in this file.

      The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
      and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

      #{new_entry}
      """

      File.write!(changelog_path, header)
    end
  end

  defp categorize(%{subject: subject}, anchors) do
    case Regex.run(~r/^(\w+)(?:\(.+?\))?:\s*(.+)$/, subject) do
      [_, prefix, message] ->
        section = Map.get(anchors, prefix)
        {section, String.trim(message)}

      _ ->
        {nil, subject}
    end
  end

  defp format_keepachangelog(version, sections, anchors) do
    date = Date.utc_today() |> Date.to_iso8601()
    header = "## [#{version}] - #{date}"

    # Order sections by their position in the anchors map
    section_order = anchors |> Map.values() |> Enum.uniq()

    body =
      section_order
      |> Enum.filter(&Map.has_key?(sections, &1))
      |> Enum.map(fn section_name ->
        items = Map.get(sections, section_name, [])
        entries = Enum.map(items, &"- #{&1}") |> Enum.join("\n")
        "### #{section_name}\n\n#{entries}"
      end)
      |> Enum.join("\n\n")

    if body == "" do
      header
    else
      "#{header}\n\n#{body}"
    end
  end
end
