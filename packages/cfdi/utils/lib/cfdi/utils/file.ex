defmodule Cfdi.Utils.File do
  @moduledoc """
  File-related utilities.
  """

  @spec is_path?(String.t()) :: boolean()
  def is_path?(input) do
    Regex.match?(~r{[/\\]|(\.\w+)$}, input)
  end
end
