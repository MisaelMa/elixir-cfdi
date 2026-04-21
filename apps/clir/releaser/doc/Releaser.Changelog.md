# `Releaser.Changelog`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/changelog.ex#L1)

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

# `generate`

Generates a changelog string from git commits.

## Options

- `:from` — Git ref to start from (default: latest tag)
- `:to` — Git ref to end at (default: `"HEAD"`)
- `:path` — Scope commits to a directory path
- `:version` — Version string for the heading
- `:anchors` — Map of prefix → section name (overrides config)

# `update_file`

Reads existing CHANGELOG.md and prepends a new version entry.

If the file doesn't exist, creates it with the standard header.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
