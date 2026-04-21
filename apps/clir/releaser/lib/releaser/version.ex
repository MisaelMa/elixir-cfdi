defmodule Releaser.Version do
  @moduledoc """
  SemVer version parsing, bumping, and pre-release tag management.

  Supports the full pre-release lifecycle:

      4.0.17                          # stable
      4.0.18-dev.1                    # first dev pre-release
      4.0.18-dev.2                    # iterate in dev
      4.0.18-beta.1                   # promote to beta (keeps base)
      4.0.18-rc.1                     # release candidate
      4.0.18                          # final release
      4.0.18+20260420                 # with build metadata

  ## Tag rules

  - **Clean version + tag**: bumps base, adds tag `.1` → `4.0.18-dev.1`
  - **Same tag**: only increments number → `4.0.18-dev.1` → `4.0.18-dev.2`
  - **Different tag**: keeps base, switches tag → `4.0.18-dev.3` → `4.0.18-beta.1`
  - **Release**: strips tag → `4.0.18-beta.2` → `4.0.18`
  """

  defstruct [:major, :minor, :patch, :pre_tag, :pre_num, :build]

  @type t :: %__MODULE__{
          major: non_neg_integer(),
          minor: non_neg_integer(),
          patch: non_neg_integer(),
          pre_tag: String.t() | nil,
          pre_num: non_neg_integer(),
          build: String.t() | nil
        }

  @doc """
  Parses a version string into a `%Releaser.Version{}` struct.

      iex> Releaser.Version.parse("4.0.18-dev.3+build.1")
      %Releaser.Version{major: 4, minor: 0, patch: 18, pre_tag: "dev", pre_num: 3, build: "build.1"}

      iex> Releaser.Version.parse("1.2.3")
      %Releaser.Version{major: 1, minor: 2, patch: 3, pre_tag: nil, pre_num: 0, build: nil}
  """
  def parse(version) when is_binary(version) do
    {version_part, build} =
      case String.split(version, "+", parts: 2) do
        [v, b] -> {v, b}
        [v] -> {v, nil}
      end

    case Regex.run(~r/^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z]+)\.(\d+))?$/, version_part) do
      [_, major, minor, patch, tag, num] ->
        %__MODULE__{
          major: String.to_integer(major),
          minor: String.to_integer(minor),
          patch: String.to_integer(patch),
          pre_tag: tag,
          pre_num: String.to_integer(num),
          build: build
        }

      [_, major, minor, patch] ->
        %__MODULE__{
          major: String.to_integer(major),
          minor: String.to_integer(minor),
          patch: String.to_integer(patch),
          pre_tag: nil,
          pre_num: 0,
          build: build
        }

      _ ->
        raise ArgumentError, "Invalid version: #{version}"
    end
  end

  @doc """
  Bumps a version by the given type (`:major`, `:minor`, `:patch`).

  Accepts a `%Releaser.Version{}` struct or a version string.
  When given a string, returns a string.

  ## Options

  - `:tag` — Pre-release tag (e.g., `"dev"`, `"beta"`, `"rc"`)
  - `:build` — Build metadata string (e.g., `"20260420"`)
  """
  def bump(version_or_struct, bump_type, opts \\ [])

  def bump(%__MODULE__{} = v, bump_type, opts) do
    tag = Keyword.get(opts, :tag)
    build = Keyword.get(opts, :build, v.build)

    bumped = do_bump(v, bump_type, tag)
    %{bumped | build: build}
  end

  def bump(version, bump_type, opts) when is_binary(version) do
    version |> parse() |> bump(bump_type, opts) |> to_string()
  end

  defp do_bump(%__MODULE__{pre_tag: current_tag, pre_num: n} = v, _bump_type, tag)
       when current_tag == tag and not is_nil(tag) do
    # Same tag: just increment (4.0.18-dev.1 → 4.0.18-dev.2)
    %{v | pre_num: n + 1, build: nil}
  end

  defp do_bump(%__MODULE__{pre_tag: current_tag} = v, _bump_type, tag)
       when not is_nil(current_tag) and not is_nil(tag) do
    # Different tag: keep base, switch tag (4.0.18-dev.3 → 4.0.18-beta.1)
    %{v | pre_tag: tag, pre_num: 1, build: nil}
  end

  defp do_bump(%__MODULE__{} = v, bump_type, nil) do
    # No tag: just bump base version
    bump_base(v)
    |> then(fn bumped -> apply_bump_type(bumped, bump_type) end)
  end

  defp do_bump(%__MODULE__{} = v, bump_type, tag) do
    # Clean version + tag: bump base + add tag
    apply_bump_type(v, bump_type)
    |> then(fn bumped -> %{bumped | pre_tag: tag, pre_num: 1, build: nil} end)
  end

  @doc """
  Strips the pre-release tag, returning the stable base version.

      iex> Releaser.Version.release(Releaser.Version.parse("4.0.18-beta.2"))
      %Releaser.Version{major: 4, minor: 0, patch: 18, pre_tag: nil, pre_num: 0, build: nil}
  """
  def release(%__MODULE__{} = v) do
    %{v | pre_tag: nil, pre_num: 0, build: nil}
  end

  @doc """
  Sets the version to an explicit version string.

      iex> Releaser.Version.set("2.0.0")
      %Releaser.Version{major: 2, minor: 0, patch: 0, pre_tag: nil, pre_num: 0, build: nil}
  """
  def set(version) when is_binary(version), do: parse(version)

  @doc """
  Returns the base version string without pre-release or build metadata.
  """
  def base_string(%__MODULE__{major: maj, minor: min, patch: pat}) do
    "#{maj}.#{min}.#{pat}"
  end

  @doc """
  Returns the major.minor string for Hex dependency specs.
  """
  def major_minor(%__MODULE__{major: maj, minor: min}), do: "#{maj}.#{min}"

  @doc """
  Returns true if the version has a pre-release tag.
  """
  def prerelease?(%__MODULE__{pre_tag: nil}), do: false
  def prerelease?(%__MODULE__{}), do: true

  defp apply_bump_type(v, :major), do: %{v | major: v.major + 1, minor: 0, patch: 0}
  defp apply_bump_type(v, :minor), do: %{v | minor: v.minor + 1, patch: 0}
  defp apply_bump_type(v, :patch), do: %{v | patch: v.patch + 1}

  defp bump_base(%__MODULE__{pre_tag: nil} = v), do: v
  defp bump_base(%__MODULE__{} = v), do: %{v | pre_tag: nil, pre_num: 0}

  defimpl String.Chars do
    def to_string(%Releaser.Version{} = v) do
      base = "#{v.major}.#{v.minor}.#{v.patch}"

      with_pre =
        if v.pre_tag do
          "#{base}-#{v.pre_tag}.#{v.pre_num}"
        else
          base
        end

      if v.build do
        "#{with_pre}+#{v.build}"
      else
        with_pre
      end
    end
  end
end
