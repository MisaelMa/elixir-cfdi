# `mix releaser.publish`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/mix/tasks/releaser.publish.ex#L1)

Publishes all monorepo apps to Hex respecting the dependency graph.

Before publishing each package, `path:` dependencies are replaced with
their Hex version (`~> X.Y`). After publishing (or on failure), the
original `mix.exs` files are restored.

## Usage

    mix releaser.publish                    # publish all apps
    mix releaser.publish --dry-run          # show plan without publishing
    mix releaser.publish --only app1,app2   # only these + their deps
    mix releaser.publish --bump patch       # bump before publishing
    mix releaser.publish --org myorg        # publish to a Hex org

## Options

    --dry-run    Show publish plan without executing
    --bump TYPE  Bump version before publishing (patch|minor|major)
    --only APPS  Comma-separated list of apps to publish
    --org ORG    Hex organization name

---

*Consult [api-reference.md](api-reference.md) for complete listing*
