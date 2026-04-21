# `Releaser.App`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/workspace.ex#L1)

Struct representing a discovered app in the workspace.

The `publish` field indicates whether this app should be published to Hex.
Set `releaser: [publish: true]` in the app's `mix.exs` to mark it as publishable.

# `t`

```elixir
@type t() :: %Releaser.App{
  deps: [String.t()],
  name: String.t(),
  path: String.t(),
  publish: boolean(),
  version: String.t()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
