defmodule Releaser.Git do
  @moduledoc """
  Git helper operations for changelog generation and post-bump hooks.
  """

  @doc """
  Returns the list of commits between two refs, optionally scoped to a path.

  Each commit is a map with `:hash`, `:subject`, and `:body` keys.
  """
  def log(opts \\ []) do
    from = Keyword.get(opts, :from)
    to = Keyword.get(opts, :to, "HEAD")
    path = Keyword.get(opts, :path)

    range = if from, do: "#{from}..#{to}", else: to

    args = ["log", range, "--format=%H||%s||%b||END", "--no-merges"]
    args = if path, do: args ++ ["--", path], else: args

    case cmd(args) do
      {output, 0} ->
        output
        |> String.split("||END")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(fn entry ->
          case String.split(entry, "||", parts: 3) do
            [hash, subject, body] ->
              %{hash: String.trim(hash), subject: String.trim(subject), body: String.trim(body)}

            [hash, subject] ->
              %{hash: String.trim(hash), subject: String.trim(subject), body: ""}

            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      {_, _code} ->
        []
    end
  end

  @doc "Creates an annotated git tag."
  def tag(tag_name, message \\ nil) do
    msg = message || tag_name
    cmd(["tag", "-a", tag_name, "-m", msg])
  end

  @doc "Stages files for commit."
  def add(paths) when is_list(paths) do
    cmd(["add" | paths])
  end

  def add(path) when is_binary(path), do: add([path])

  @doc "Creates a git commit with the given message."
  def commit(message) do
    cmd(["commit", "-m", message])
  end

  @doc "Returns the latest git tag, or nil if none."
  def latest_tag do
    case cmd(["describe", "--tags", "--abbrev=0"]) do
      {tag, 0} -> String.trim(tag)
      _ -> nil
    end
  end

  @doc "Returns true if the working tree has uncommitted changes."
  def dirty? do
    case cmd(["status", "--porcelain"]) do
      {output, 0} -> String.trim(output) != ""
      _ -> true
    end
  end

  defp cmd(args) do
    System.cmd("git", args, stderr_to_stdout: true)
  end
end
