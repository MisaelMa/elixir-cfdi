defmodule Cfdi.Schema.Common.JsonProcessor do
  @moduledoc false

  @behaviour Cfdi.Schema.Common.BaseProcessor

  @impl true
  def process(bin, _loader) do
    {:ok, {:json, bin}}
  end
end
