# `Releaser.Config`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/config.ex#L1)

Configuration schema and defaults for Releaser.

All configuration lives under the `:releaser` key in your root `mix.exs` project config.

## Options

- `:apps_root` — Root directory containing your apps. Default: `"apps"`
- `:version_files` — List of `{glob_or_path, regex}` tuples for multi-file version sync
- `:changelog` — Changelog configuration (see below)
- `:hooks` — Pre/post hook modules (see below)
- `:publisher` — Hex publishing configuration (see below)

## Changelog options

- `:anchors` — Map of commit prefix to changelog section.
  Default: `%{"feat" => "Added", "fix" => "Fixed", "refactor" => "Changed", "docs" => "Documentation", "perf" => "Performance", "breaking" => "Breaking Changes"}`
- `:path` — Path to CHANGELOG.md. Default: `"CHANGELOG.md"`
- `:format` — `:keepachangelog` (default)

## Hooks options

- `:pre` — List of modules implementing `Releaser.Hooks.PreHook`
- `:post` — List of modules implementing `Releaser.Hooks.PostHook`

## Publisher options

- `:org` — Hex organization name (optional)
- `:package_defaults` — Default `package/0` config injected into apps that lack it.
  Keys: `:licenses`, `:links`, `:files`

# `defaults`

Returns the default configuration.

# `load`

Loads configuration from the host project's mix.exs, merged with defaults.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
