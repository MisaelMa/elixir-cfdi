# `Releaser.Hooks.GitTag`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/hooks/git_tag.ex#L1)

Built-in post-hook that creates a git commit and tag after bumping.

Stages changed `mix.exs` files, creates a commit with a descriptive message,
and tags with the app name and version.

## Commit format

    bump: cfdi_xml 4.0.18 → 4.0.19

## Tag format

    cfdi_xml-v4.0.19

Add to your config:

    releaser: [hooks: [post: [Releaser.Hooks.GitTag]]]

---

*Consult [api-reference.md](api-reference.md) for complete listing*
