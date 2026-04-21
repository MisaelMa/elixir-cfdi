defmodule Cfdi.Cleaner.Cleaners.RemoveNonSatSchemaLocations do
  @moduledoc false

  alias Cfdi.Cleaner.Cleaners.SatNamespaces

  @doc """
  Filtra pares en `xsi:schemaLocation` dejando solo URIs consideradas SAT.
  """
  @spec clean(String.t()) :: String.t()
  def clean(xml) when is_binary(xml) do
    Regex.replace(~r/\sxsi:schemaLocation="([^"]*)"/, xml, fn _full, pairs ->
      filtered =
        pairs
        |> String.split(~r/\s+/, trim: true)
        |> Enum.chunk_every(2)
        |> Enum.filter(fn
          [ns, _loc] -> SatNamespaces.sat_namespace_uri?(ns)
          _ -> false
        end)
        |> List.flatten()
        |> Enum.join(" ")

      if filtered == "" do
        ""
      else
        ~s( xsi:schemaLocation="#{filtered}")
      end
    end)
  end
end
