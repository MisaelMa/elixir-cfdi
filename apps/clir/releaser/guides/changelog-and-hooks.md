# Changelog and Hooks

This guide covers automated changelog generation and the hook system
for running custom logic before and after version bumps.

## Changelog

Releaser generates changelogs from git commits using
[conventional commit](https://www.conventionalcommits.org/) prefixes.

### Commit format

Write your commits like this:

```
feat: add CartaPorte 3.1 complement support
fix: correct UTF-8 encoding in XML attributes
refactor: extract version parsing to Version struct
docs: update publishing guide with org examples
perf: cache XSD schema parsing results
breaking: remove deprecated cer/key modules
```

The prefix before `:` maps to a changelog section.

### Default mappings

| Prefix | Changelog section |
|---|---|
| `feat` | Added |
| `fix` | Fixed |
| `refactor` | Changed |
| `docs` | Documentation |
| `perf` | Performance |
| `breaking` | Breaking Changes |

### Generate a changelog

```bash
# Preview without writing
$ mix releaser.changelog cfdi_xml --dry-run

Changelog for cfdi_xml:

## [4.0.19] - 2026-04-20

### Added

- add CartaPorte 3.1 complement support
- add Certificate.toBase64() method

### Fixed

- correct UTF-8 encoding in XML attributes

### Changed

- migrate certificar() to use Certificate class

--dry-run: no files written
```

```bash
# Write to CHANGELOG.md
$ mix releaser.changelog cfdi_xml
Updated apps/cfdi/xml/CHANGELOG.md
```

### Scope by git ref

```bash
# Changes since a specific tag
$ mix releaser.changelog cfdi_xml --from cfdi_xml-v4.0.18

# Changes in a range
$ mix releaser.changelog --from v1.0.0 --to v2.0.0
```

### Custom anchors

Override the default prefix → section mapping:

```elixir
releaser: [
  changelog: [
    anchors: %{
      "feat" => "New Features",
      "fix" => "Bug Fixes",
      "security" => "Security",
      "deprecate" => "Deprecated",
      "remove" => "Removed"
    }
  ]
]
```

## Hooks

Hooks let you run custom code before and after version bumps.

### Built-in hooks

Releaser includes two ready-to-use hooks:

#### `Releaser.Hooks.GitTag`

After a bump, stages the changed `mix.exs` files, creates a commit, and
tags it:

```
Commit: "bump: version update"
Tag:    "cfdi_xml-v4.0.19"
```

#### `Releaser.Hooks.ChangelogHook`

After a bump, generates/updates the CHANGELOG.md in the app's directory.

### Enable hooks

Add them to your config:

```elixir
releaser: [
  hooks: [
    post: [
      Releaser.Hooks.GitTag,
      Releaser.Hooks.ChangelogHook
    ]
  ]
]
```

Now when you bump:

```bash
$ mix releaser.bump cfdi_xml patch

Version changes:
  cfdi_xml                  4.0.18 → 4.0.19   (direct)

1 app(s) updated
  changelog apps/cfdi/xml/CHANGELOG.md
  tagged cfdi_xml-v4.0.19
```

### Skip hooks for a single run

```bash
$ mix releaser.bump cfdi_xml patch --no-hooks
```

### Writing custom hooks

#### Pre-hook example: ensure clean working tree

```elixir
defmodule MyProject.Hooks.EnsureClean do
  @behaviour Releaser.Hooks.PreHook

  @impl true
  def run(_context) do
    if Releaser.Git.dirty?() do
      {:error, "Working tree is dirty. Commit or stash changes first."}
    else
      :ok
    end
  end
end
```

#### Post-hook example: notify Slack

```elixir
defmodule MyProject.Hooks.NotifySlack do
  @behaviour Releaser.Hooks.PostHook

  @impl true
  def run(%{app: app, new_version: version, changes: changes}) do
    count = length(changes)
    message = "Released #{app} v#{version} (#{count} package(s) updated)"

    # Your Slack API call here...
    Slack.post_message("#releases", message)

    :ok
  end
end
```

#### Post-hook example: run tests before tagging

```elixir
defmodule MyProject.Hooks.RunTests do
  @behaviour Releaser.Hooks.PreHook

  @impl true
  def run(%{app: app, path: path}) do
    case System.cmd("mix", ["test"], cd: path, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _} -> {:error, "Tests failed for #{app}:\n#{output}"}
    end
  end
end
```

### Hook context

Both pre and post hooks receive a context map:

```elixir
%{
  app: "cfdi_xml",                    # app being bumped
  path: "apps/cfdi/xml",             # path to the app
  old_version: "4.0.18",             # version before bump
  new_version: "4.0.19",             # version after bump
  bump_type: :patch,                 # :patch | :minor | :major | :release | :explicit
  changes: [                         # all planned changes (including cascade)
    %{app: "cfdi_xml", path: "...", old: "4.0.18", new: "4.0.19", reason: :direct},
    %{app: "cfdi_designs", path: "...", old: "1.0.0", new: "1.0.1", reason: :cascade}
  ],
  apps: [%Releaser.App{}, ...]       # all discovered apps
}
```

### Hook execution order

1. All pre-hooks run (in config order)
2. If any pre-hook returns `{:error, reason}`, the bump is aborted
3. Version files are updated
4. All post-hooks run (in config order)
5. If a post-hook fails, a warning is printed but the bump is not rolled back

### Full hook configuration example

```elixir
releaser: [
  hooks: [
    pre: [
      MyProject.Hooks.EnsureClean,
      MyProject.Hooks.RunTests
    ],
    post: [
      Releaser.Hooks.ChangelogHook,
      Releaser.Hooks.GitTag,
      MyProject.Hooks.NotifySlack
    ]
  ]
]
```
