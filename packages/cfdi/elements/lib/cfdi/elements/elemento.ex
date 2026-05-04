defmodule Cfdi.Elements.Elemento do
  @moduledoc """
  Represents a qualified XML element name (prefix:localName).
  """

  defstruct [:prefix, :name, :tag]

  @type t :: %__MODULE__{
          prefix: String.t(),
          name: String.t(),
          tag: String.t()
        }

  @spec new(String.t()) :: t()
  def new(tag) do
    [prefix, name] = String.split(tag, ":", parts: 2)
    %__MODULE__{prefix: prefix, name: name, tag: tag}
  end
end
