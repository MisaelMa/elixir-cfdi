defmodule Cfdi.Cleaner.Cleaners.SatNamespaces do
  @moduledoc false

  @doc """
  URIs de espacios de nombres reconocidos por el SAT para CFDI y complementos
  frecuentes (lista orientativa para limpieza).
  """
  @sat_namespaces %{
    "http://www.sat.gob.mx/cfd/4" => true,
    "http://www.sat.gob.mx/cfd/3" => true,
    "http://www.sat.gob.mx/TimbreFiscalDigital" => true,
    "http://www.w3.org/2001/XMLSchema-instance" => true
  }

  def sat_namespaces, do: @sat_namespaces

  @spec sat_namespace_uri?(String.t()) :: boolean()
  def sat_namespace_uri?(uri) when is_binary(uri) do
    Map.has_key?(@sat_namespaces, uri) or String.starts_with?(uri, "http://www.sat.gob.mx/")
  end
end
