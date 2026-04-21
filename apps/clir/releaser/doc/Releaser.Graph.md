# `Releaser.Graph`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/graph.ex#L1)

Dependency graph building and topological sorting for monorepo apps.

Builds a directed graph from internal `path:` dependencies and provides
topological ordering for correct publish order, dependency resolution,
and cascade planning.

# `build`

Builds a dependency graph from a list of apps.

Returns a map of `%{app_name => [dependency_names]}`.

# `dependents_of`

Returns a map of `%{app_name => [dependent_names]}` (reverse graph).

For each app, lists which apps depend on it.

# `filter_levels`

Filters topological levels to only include the specified apps.
Removes empty levels.

# `topological_levels`

Computes topological levels using Kahn's algorithm.

Returns `[{level, [app_names]}]` where level 0 has no internal deps,
level 1 depends only on level 0, etc.

# `transitive_dependents`

Resolves transitive dependents for a list of app names (reverse direction).

Given an app, returns all apps that depend on it recursively (upstream).
For example, if `cfdi_xml` depends on `cfdi_csd`, then `cfdi_xml` is a
transitive dependent of `cfdi_csd`.

This is the inverse of `transitive_deps/2`.

# `transitive_deps`

Resolves transitive dependencies for a list of app names.

Returns a MapSet of all apps that need to be included (the requested
apps plus all their transitive dependencies).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
