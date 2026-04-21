# `Releaser.Workspace`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/workspace.ex#L19)

Discovers apps in a poncho/umbrella project.

Scans the configured `apps_root` directory for Mix projects and extracts
their name, version, and internal (path-based) dependencies.

Supports both flat (`apps/foo/mix.exs`) and nested (`apps/group/foo/mix.exs`) layouts.

# `discover`

Discovers all apps in the workspace.

Returns a list of `%Releaser.App{}` structs sorted by name.

# `find`

Finds a single app by name. Returns `nil` if not found.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
