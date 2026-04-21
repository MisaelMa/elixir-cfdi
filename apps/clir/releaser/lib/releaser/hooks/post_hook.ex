defmodule Releaser.Hooks.PostHook do
  @moduledoc """
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
  """

  @type context :: %{
          app: String.t(),
          old_version: String.t(),
          new_version: String.t(),
          bump_type: atom(),
          changes: [map()],
          apps: [Releaser.App.t()]
        }

  @callback run(context()) :: :ok | {:error, term()}
end
