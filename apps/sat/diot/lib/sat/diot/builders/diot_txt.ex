defmodule Sat.Diot.Builders.DiotTxt do
  @moduledoc """
  Generates DIOT text file content in pipe-delimited format.
  """

  alias Sat.Diot.Types
  alias Sat.Diot.Types.{Declaracion, OperacionTercero}

  @spec build(Declaracion.t()) :: String.t()
  def build(%Declaracion{operaciones: []}) do
    ""
  end

  def build(%Declaracion{operaciones: operaciones}) do
    operaciones
    |> Enum.map(&fila_operacion/1)
    |> Enum.join("\n")
  end

  defp fila_operacion(%OperacionTercero{} = op) do
    [
      Types.tipo_tercero_value(op.tipo_tercero),
      Types.tipo_operacion_value(op.tipo_operacion),
      celda(op.rfc),
      celda(op.id_fiscal),
      celda(op.nombre_extranjero),
      celda(op.pais_residencia),
      celda(op.nacionalidad),
      format_monto(op.monto_iva_16),
      format_monto(op.monto_iva_0),
      format_monto(op.monto_exento),
      format_monto(op.monto_retenido),
      format_monto(op.monto_iva_no_deduc)
    ]
    |> Enum.join("|")
  end

  defp celda(nil), do: ""
  defp celda(val), do: String.trim(val)

  defp format_monto(value) when is_number(value) do
    :erlang.float_to_binary(value / 1, decimals: 2)
  end
end
