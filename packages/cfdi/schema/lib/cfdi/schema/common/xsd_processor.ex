defmodule Cfdi.Schema.Common.XsdProcessor do
  @moduledoc false

  @behaviour Cfdi.Schema.Common.BaseProcessor

  @impl true
  def process(bin, _loader) do
    case Saxy.SimpleForm.parse_string(bin) do
      {:ok, form} -> {:ok, form}
      {:error, _} = e -> e
    end
  end
end
