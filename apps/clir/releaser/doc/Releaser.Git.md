# `Releaser.Git`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/git.ex#L1)

Git helper operations for changelog generation and post-bump hooks.

# `add`

Stages files for commit.

# `commit`

Creates a git commit with the given message.

# `dirty?`

Returns true if the working tree has uncommitted changes.

# `latest_tag`

Returns the latest git tag, or nil if none.

# `log`

Returns the list of commits between two refs, optionally scoped to a path.

Each commit is a map with `:hash`, `:subject`, and `:body` keys.

# `tag`

Creates an annotated git tag.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
