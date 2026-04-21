defmodule Cfdi.Cleaner.Cleaners.RemoveNonSatNamespaces do
  @moduledoc false

  alias Cfdi.Cleaner.Cleaners.SatNamespaces

  @doc """
  Quita declaraciones `xmlns` y `xmlns:prefijo` cuya URI no sea SAT.
  """
  @spec clean(String.t()) :: String.t()
  def clean(xml) when is_binary(xml) do
    xml
    |> Regex.replace(~r/\sxmlns="([^"]*)"/, fn full, uri ->
      if SatNamespaces.sat_namespace_uri?(uri), do: full, else: ""
    end)
    |> Regex.replace(~r/\sxmlns:([A-Za-z0-9_-]+)="([^"]*)"/, fn full, _prefix, uri ->
      if SatNamespaces.sat_namespace_uri?(uri), do: full, else: ""
    end)
  end
end
