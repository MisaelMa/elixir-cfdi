# `Releaser.HexStatus`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/hex_status.ex#L1)

Compares local app versions against published versions on Hex.

Uses `mix hex.info <package>` to query the Hex registry.

# `status`

```elixir
@type status() :: :ahead | :published | :unpublished | :prerelease
```

# `check`

Checks all apps and returns their publish status.

Returns a list of maps with `:app`, `:local`, `:hex`, and `:status` keys.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
