# `Releaser.Hooks.ChangelogHook`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/hooks/changelog_hook.ex#L1)

Built-in post-hook that generates/updates CHANGELOG.md after a bump.

Uses conventional commit prefixes to categorize changes into
keepachangelog sections.

Add to your config:

    releaser: [hooks: [post: [Releaser.Hooks.ChangelogHook]]]

---

*Consult [api-reference.md](api-reference.md) for complete listing*
