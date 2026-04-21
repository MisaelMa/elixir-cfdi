# `mix releaser.changelog`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/mix/tasks/releaser.changelog.ex#L1)

Generates a changelog entry from git commits using conventional commit prefixes.

## Usage

    mix releaser.changelog                  # generate for all apps
    mix releaser.changelog <app>            # generate for one app
    mix releaser.changelog --from v1.0.0    # from a specific git ref

## Options

    --from REF     Start from a specific git ref (default: latest tag)
    --to REF       End at a specific git ref (default: HEAD)
    --dry-run      Show changelog without writing to file

---

*Consult [api-reference.md](api-reference.md) for complete listing*
