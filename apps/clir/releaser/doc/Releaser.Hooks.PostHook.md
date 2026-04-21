# `Releaser.Hooks.PostHook`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/releaser/hooks/post_hook.ex#L1)

Behaviour for post-bump hooks.

Post-hooks run after the version bump is applied. They receive a context
map with the results of the bump.

## Example

    defmodule MyProject.NotifySlack do
      @behaviour Releaser.Hooks.PostHook

      @impl true
      def run(context) do
        # Send notification...
        :ok
      end
    end

Then configure:

    releaser: [hooks: [post: [Releaser.Hooks.GitTag, MyProject.NotifySlack]]]

# `context`

```elixir
@type context() :: %{
  app: String.t(),
  old_version: String.t(),
  new_version: String.t(),
  bump_type: atom(),
  changes: [map()],
  apps: [Releaser.App.t()]
}
```

# `run`

```elixir
@callback run(context()) :: :ok | {:error, term()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
