# `Releaser.Publisher`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/publisher.ex#L1)

Orchestrates publishing multiple apps to Hex in topological order.

For each app (in dependency order):
1. Backs up the original `mix.exs`
2. Replaces `path:` deps with their published Hex versions (`~> X.Y`)
3. Injects `package/0` metadata if missing
4. Runs `mix hex.publish --yes`
5. Restores the original `mix.exs` (always, even on failure)

# `ensure_package_config`

# `execute`

Executes the publish flow.

# `plan`

Plans the publish order and returns a list of levels with app info.
Does not modify anything.

# `replace_path_dep`

# `restore`

Restores backed-up mix.exs files.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
