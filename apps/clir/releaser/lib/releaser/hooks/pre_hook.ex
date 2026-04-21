defmodule Releaser.Hooks.PreHook do
  @moduledoc """
  Behaviour for pre-bump hooks.

  Pre-hooks run before the version bump is applied. They receive a context
  map and can abort the bump by returning `{:error, reason}`.

  ## Example

      defmodule MyProject.EnsureCleanTree do
        @behaviour Releaser.Hooks.PreHook

        @impl true
        def run(context) do
          if Releaser.Git.dirty?() do
            {:error, "Working tree is dirty. Commit or stash your changes first."}
          else
            :ok
          end
        end
      end

  Then configure:

      releaser: [hooks: [pre: [MyProject.EnsureCleanTree]]]
  """

  @type context :: %{
          app: String.t(),
          old_version: String.t(),
          new_version: String.t(),
          bump_type: atom(),
          apps: [Releaser.App.t()]
        }

  @callback run(context()) :: :ok | {:error, term()}
end
