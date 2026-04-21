# `Releaser.FileSync`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/file_sync.ex#L1)

Syncs version numbers across multiple files.

Besides `mix.exs` (which is always updated), you can configure additional
files like README.md, Dockerfile, or any file containing a version string.

## Configuration

    releaser: [
      version_files: [
        {"README.md", ~r/version "(+.+.+)"/},
        {"Dockerfile", ~r/ARG VERSION=(S+)/}
      ]
    ]

# `sync_files`

Syncs version in all configured additional files for the given app.

`files` is a list of `{path_or_glob, regex}` tuples where the regex
must contain a capture group matching the version string to replace.

# `update_mix_version`

Updates the version in `mix.exs` for the given app path.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
