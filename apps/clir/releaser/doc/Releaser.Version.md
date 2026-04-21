# `Releaser.Version`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/version.ex#L1)

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

# `t`

```elixir
@type t() :: %Releaser.Version{
  build: String.t() | nil,
  major: non_neg_integer(),
  minor: non_neg_integer(),
  patch: non_neg_integer(),
  pre_num: non_neg_integer(),
  pre_tag: String.t() | nil
}
```

# `base_string`

Returns the base version string without pre-release or build metadata.

# `bump`

Bumps a version by the given type (`:major`, `:minor`, `:patch`).

Accepts a `%Releaser.Version{}` struct or a version string.
When given a string, returns a string.

## Options

- `:tag` — Pre-release tag (e.g., `"dev"`, `"beta"`, `"rc"`)
- `:build` — Build metadata string (e.g., `"20260420"`)

# `major_minor`

Returns the major.minor string for Hex dependency specs.

# `parse`

Parses a version string into a `%Releaser.Version{}` struct.

    iex> Releaser.Version.parse("4.0.18-dev.3+build.1")
    %Releaser.Version{major: 4, minor: 0, patch: 18, pre_tag: "dev", pre_num: 3, build: "build.1"}

    iex> Releaser.Version.parse("1.2.3")
    %Releaser.Version{major: 1, minor: 2, patch: 3, pre_tag: nil, pre_num: 0, build: nil}

# `prerelease?`

Returns true if the version has a pre-release tag.

# `release`

Strips the pre-release tag, returning the stable base version.

    iex> Releaser.Version.release(Releaser.Version.parse("4.0.18-beta.2"))
    %Releaser.Version{major: 4, minor: 0, patch: 18, pre_tag: nil, pre_num: 0, build: nil}

# `set`

Sets the version to an explicit version string.

    iex> Releaser.Version.set("2.0.0")
    %Releaser.Version{major: 2, minor: 0, patch: 0, pre_tag: nil, pre_num: 0, build: nil}

---

*Consult [api-reference.md](api-reference.md) for complete listing*
