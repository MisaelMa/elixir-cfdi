# `Releaser.Cascade`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/cascade.ex#L1)

Plans cascade version bumps through the dependency graph.

When a package is bumped, all packages that depend on it receive
a patch bump automatically (like Rush in Node.js).

# `plan`

Plans version changes for an app and its publishable dependents.

Only cascades to apps with `publish: true`. Non-publishable apps are
skipped — their version in Hex (if any) is already covered by `~>` constraints.

Returns a list of `%{app: name, path: path, old: version, new: version, reason: atom}`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
