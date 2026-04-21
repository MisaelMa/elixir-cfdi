defmodule Cfdi.Expresiones.Transform do
  @moduledoc """
  Transforms a CFDI JSON/map representation into a pipe-separated expression string.
  """

  @omit_keys ~w(xmlns:cfdi xmlns:xsi xsi:schemaLocation Certificado xmlns:destruccion xmlns:iedu xmlns:pago10)
  @ignore_keys ~w(Sello)

  @comprobante_order [
    "_attributes",
    "cfdi:InformacionGlobal",
    "cfdi:CfdiRelacionados",
    "cfdi:Emisor",
    "cfdi:Receptor",
    "cfdi:Conceptos",
    "cfdi:Impuestos",
    "cfdi:Complemento"
  ]

  @spec run(map()) :: String.t()
  def run(xml) when is_map(xml) do
    comprobante = Map.get(xml, "cfdi:Comprobante", %{})
    values = obtener_valores(comprobante, ordered: true)
    "||#{values |> Enum.filter(& &1) |> Enum.join("|")}||"
  end

  defp obtener_valores(obj, opts) when is_map(obj) do
    ordered = Keyword.get(opts, :ordered, false)
    keys = if ordered, do: @comprobante_order, else: Map.keys(obj)

    Enum.flat_map(keys, fn key ->
      if key in @omit_keys do
        []
      else
        case Map.get(obj, key) do
          nil ->
            []

          value when is_map(value) ->
            obtener_valores(value, ordered: false)

          value when is_list(value) ->
            Enum.flat_map(value, fn item ->
              if is_map(item),
                do: obtener_valores(item, ordered: false),
                else: [item]
            end)

          value ->
            if key in @ignore_keys, do: [], else: [value]
        end
      end
    end)
  end

  defp obtener_valores(obj, _opts) when is_list(obj) do
    Enum.flat_map(obj, fn
      item when is_map(item) -> obtener_valores(item, ordered: false)
      item -> [item]
    end)
  end

  defp obtener_valores(_, _), do: []
end
