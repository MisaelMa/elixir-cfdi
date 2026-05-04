defmodule Cfdi.Schema.Common.BaseProcessor do
  @moduledoc false

  @callback process(binary(), Cfdi.Schema.t()) :: {:ok, term()} | {:error, term()}
end
