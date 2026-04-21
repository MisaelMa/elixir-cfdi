# Releaser

Monorepo versioning, changelog, and Hex publishing for Elixir poncho/umbrella projects.

The **only Hex package** that handles versioning + publishing for Elixir monorepos
with internal dependencies. Think Rush (Node.js) but for Elixir.

## Features

| Feature | Releaser | Versioce | GitHub Tag Bump |
|---|---|---|---|
| SemVer bump (patch/minor/major) | Yes | Yes | Yes |
| Pre-release tags (dev, beta, rc) | Yes | Partial | Partial |
| Same tag increments (dev.1 → dev.2) | **Yes** | No | No |
| Tag change keeps base (dev → beta) | **Yes** | No | No |
| Release (strip tag) | **Yes** | No | No |
| Cascade bumps to dependents | **Yes** | No | No |
| Dependency graph (visual) | **Yes** | No | No |
| Topological Hex publishing | **Yes** | No | No |
| Release status (local vs Hex) | **Yes** | No | No |
| Changelog from git commits | Yes | Yes | No |
| Git hooks (commit + tag) | Yes | Yes | No |
| Multi-file version sync | Yes | Yes | No |
| Build metadata | Yes | Yes | No |
| Explicit version set | Yes | Yes | Yes |
| Monorepo / poncho support | **Yes** | No | No |

## Installation

Add to your **root** `mix.exs`:

```elixir
defp deps do
  [
    {:releaser, "~> 0.1", only: :dev, runtime: false}
  ]
end
```

## Quick start

```bash
# List all apps and versions
mix releaser.bump --list

# See dependency graph
mix releaser.graph

# Bump a package
mix releaser.bump my_app patch

# Check what needs publishing
mix releaser.status

# Publish everything to Hex
mix releaser.publish --dry-run
```

## Versioning

### Basic bump

```bash
mix releaser.bump my_app patch        # 4.0.17 → 4.0.18
mix releaser.bump my_app minor        # 4.0.17 → 4.1.0
mix releaser.bump my_app major        # 4.0.17 → 5.0.0
```

### Explicit version

```bash
mix releaser.bump my_app 2.0.0        # set to exact version
```

### Build metadata

```bash
mix releaser.bump my_app patch --build 20260420    # 4.0.18+20260420
```

### Bump all apps

```bash
mix releaser.bump --all patch          # bump every app
```

## Pre-release tags

Full lifecycle support for pre-release versions following SemVer 2.0.

### Lifecycle

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                   Version lifecycle                             │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  4.0.17 (current stable)                                        │
  │    │                                                            │
  │    ├── releaser.bump my_app patch --tag dev                     │
  │    │     → 4.0.18-dev.1          bump base + add tag            │
  │    │                                                            │
  │    ├── releaser.bump my_app patch --tag dev                     │
  │    │     → 4.0.18-dev.2          same tag = increment only      │
  │    │                                                            │
  │    ├── releaser.bump my_app patch --tag dev                     │
  │    │     → 4.0.18-dev.3          another dev fix                │
  │    │                                                            │
  │    ├── releaser.bump my_app patch --tag beta                    │
  │    │     → 4.0.18-beta.1         tag change = keeps base        │
  │    │                                                            │
  │    ├── releaser.bump my_app patch --tag beta                    │
  │    │     → 4.0.18-beta.2         beta fix                       │
  │    │                                                            │
  │    ├── releaser.bump my_app patch --tag rc                      │
  │    │     → 4.0.18-rc.1           release candidate              │
  │    │                                                            │
  │    ├── releaser.bump my_app release                             │
  │    │     → 4.0.18                strip tag = stable release     │
  │    │                                                            │
  │  4.0.18 (new stable)                                            │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
```

### Tag rules

| Situation | Command | Result |
|---|---|---|
| Clean `4.0.17` | `patch --tag dev` | `4.0.18-dev.1` (bump + tag) |
| Same tag `-dev.2` | `patch --tag dev` | `4.0.18-dev.3` (increment) |
| Different tag `-dev.3` | `patch --tag beta` | `4.0.18-beta.1` (keep base) |
| Any tag `-beta.2` | `release` | `4.0.18` (strip tag) |

### Available tags

| Tag | Usage |
|---|---|
| `dev` | Active development, may break things |
| `alpha` | First internal test version |
| `beta` | Feature-complete, may have bugs |
| `rc` | Release candidate, production-ready except bugs |

SemVer ordering: `alpha < beta < dev < rc < stable`

## Cascade bumps

When you bump a package, all packages that depend on it automatically
receive a patch bump:

```bash
mix releaser.bump clir_openssl minor --dry-run
```

```
Version changes:
  clir_openssl              0.0.17 → 0.1.0   (direct)
  cfdi_csd                  4.0.16 → 4.0.17   (cascade)
  sat_auth                  1.0.1  → 1.0.2    (cascade)
  cfdi_xml                  4.0.18 → 4.0.19   (cascade)
  cfdi_cancelacion          0.0.1  → 0.0.2    (cascade)
  cfdi_descarga             0.0.1  → 0.0.2    (cascade)
```

Disable with `--no-cascade`.

## Dependency graph

```bash
mix releaser.graph
```

```
╔══════════════════════════════════════════════════╗
║           Dependency Graph                       ║
╚══════════════════════════════════════════════════╝

┌── Level 0  (no internal deps) ──┐
│   cfdi_catalogos v4.0.16
│   clir_openssl v0.0.17
│   saxon_he v12.5.2
│   ... (28 apps)
│       ▼
┌── Level 1 ──┐
│   cfdi_csd v4.0.16
│   └─ depends on: clir_openssl
│       ▼
┌── Level 2 ──┐
│   cfdi_xml v4.0.18
│   └─ depends on: cfdi_csd, cfdi_transform, ...
│   sat_auth v1.0.1
│   └─ depends on: cfdi_csd
│       ▼
┌── Level 3 ──┐
│   cfdi_cancelacion v0.0.1
│   └─ depends on: sat_auth
└── end ──┘
```

Show dependents of a specific app:

```bash
mix releaser.graph cfdi_csd
```

```
Dependents of cfdi_csd:
  └─ sat_auth
    └─ cfdi_cancelacion
    └─ cfdi_descarga
  └─ cfdi_xml
```

## Publishing to Hex

Publishes all packages in topological order (dependencies first).
Automatically replaces `path:` deps with Hex versions and restores
after publishing.

```bash
# See the publish plan
mix releaser.publish --dry-run

# Publish everything
mix releaser.publish

# Bump + publish
mix releaser.publish --bump patch

# Only specific apps (+ their deps automatically)
mix releaser.publish --only cfdi_xml

# Publish to a Hex organization
mix releaser.publish --org myorg
```

### What happens internally

For each package (in dependency order):

1. Backup `mix.exs`
2. Bump version (if `--bump`)
3. Replace `{:dep, path: "..."}` → `{:dep, "~> X.Y"}`
4. Inject `package/0` if missing
5. `mix hex.publish --yes`
6. Restore original `mix.exs` (always, even on failure)

## Release status

Compare local versions against what's published on Hex:

```bash
mix releaser.status
```

```
Package              Local       Hex         Status
cfdi_xml             4.0.19      4.0.18      ahead
cfdi_csd             4.0.16      4.0.16      published
cfdi_complementos    4.0.18-dev.1  4.0.17    pre-release
my_new_app           0.1.0       —           unpublished

2 package(s) need publishing.
```

## Changelog

Generate changelogs from git commits using conventional commit prefixes:

```bash
# Generate for all apps
mix releaser.changelog

# Generate for one app
mix releaser.changelog cfdi_xml

# Preview without writing
mix releaser.changelog --dry-run

# From a specific ref
mix releaser.changelog --from v4.0.17
```

Commits should follow conventional commits:

```
feat: add CartaPorte 3.1 support
fix: correct XML encoding for special characters
refactor: extract version parsing to struct
breaking: remove deprecated cer/key modules
```

Output follows [Keep a Changelog](https://keepachangelog.com/) format.

## Hooks

Pre and post-bump hooks for custom automation.

### Built-in hooks

| Hook | Type | What it does |
|---|---|---|
| `Releaser.Hooks.GitTag` | post | `git add` + `git commit` + `git tag` |
| `Releaser.Hooks.ChangelogHook` | post | Generate/update CHANGELOG.md |

### Custom hooks

```elixir
defmodule MyProject.NotifySlack do
  @behaviour Releaser.Hooks.PostHook

  @impl true
  def run(%{app: app, new_version: version, changes: changes}) do
    # Send Slack notification...
    :ok
  end
end
```

### Disable hooks

```bash
mix releaser.bump my_app patch --no-hooks
```

## Configuration

All config lives in your root `mix.exs` under the `:releaser` key:

```elixir
def project do
  [
    app: :my_project,
    version: "0.1.0",
    deps: deps(),
    releaser: [
      # Root directory containing apps (default: "apps")
      apps_root: "apps",

      # Additional files to sync version in
      version_files: [
        {"README.md", ~r/@version (\S+)/},
        {"Dockerfile", ~r/ARG VERSION=(\S+)/}
      ],

      # Changelog configuration
      changelog: [
        path: "CHANGELOG.md",
        anchors: %{
          "feat" => "Added",
          "fix" => "Fixed",
          "refactor" => "Changed",
          "docs" => "Documentation",
          "perf" => "Performance",
          "breaking" => "Breaking Changes"
        }
      ],

      # Pre/post hooks
      hooks: [
        pre: [],
        post: [Releaser.Hooks.GitTag, Releaser.Hooks.ChangelogHook]
      ],

      # Hex publishing defaults
      publisher: [
        org: nil,
        package_defaults: [
          licenses: ["MIT"],
          links: %{"GitHub" => "https://github.com/me/project"},
          files: ~w(lib mix.exs README.md LICENSE)
        ]
      ]
    ]
  ]
end
```

## All commands

```bash
# Versioning
mix releaser.bump <app> <major|minor|patch>     # bump with cascade
mix releaser.bump <app> <major|minor|patch> --tag dev
mix releaser.bump <app> release                  # strip pre-release
mix releaser.bump <app> 2.0.0                    # explicit version
mix releaser.bump --list                         # list versions
mix releaser.bump --all patch                    # bump all apps

# Graph
mix releaser.graph                               # full dependency graph
mix releaser.graph <app>                         # dependents of app

# Publishing
mix releaser.publish                             # publish all to Hex
mix releaser.publish --dry-run                   # show plan
mix releaser.publish --only app1,app2            # only these + deps
mix releaser.publish --bump patch                # bump before publish
mix releaser.publish --org myorg                 # Hex organization

# Status
mix releaser.status                              # local vs Hex comparison

# Changelog
mix releaser.changelog                           # generate for all
mix releaser.changelog <app>                     # generate for one
mix releaser.changelog --from v1.0.0             # from specific ref

# Global options (all commands)
--dry-run                                        # preview without changes
--no-hooks                                       # skip pre/post hooks
```

## Recommended workflow

```bash
# 1. Start development
mix releaser.bump my_app patch --tag dev

# 2. Iterate
mix releaser.bump my_app patch --tag dev          # dev.1 → dev.2

# 3. Promote to beta
mix releaser.bump my_app patch --tag beta          # dev.3 → beta.1

# 4. Release candidate
mix releaser.bump my_app patch --tag rc

# 5. Final release
mix releaser.bump my_app release                   # rc.1 → stable

# 6. Check what needs publishing
mix releaser.status

# 7. Publish
mix releaser.publish
```

## License

MIT
