defmodule Cfdi.Types.Concepto do
  @moduledoc """
  Atributos y colecciones hijas típicas de `cfdi:Concepto`.
  """

  defstruct [
    :ClaveProdServ,
    :NoIdentificacion,
    :Cantidad,
    :ClaveUnidad,
    :Unidad,
    :Descripcion,
    :ValorUnitario,
    :Importe,
    :Descuento,
    :ObjetoImp,
    :impuestos,
    :informacion_aduanera,
    :cuenta_predial,
    :parte
  ]

  @type t :: %__MODULE__{
          ClaveProdServ: String.t() | nil,
          NoIdentificacion: String.t() | nil,
          Cantidad: String.t() | nil,
          ClaveUnidad: String.t() | nil,
          Unidad: String.t() | nil,
          Descripcion: String.t() | nil,
          ValorUnitario: String.t() | nil,
          Importe: String.t() | nil,
          Descuento: String.t() | nil,
          ObjetoImp: String.t() | nil,
          impuestos: list() | nil,
          informacion_aduanera: list() | nil,
          cuenta_predial: list() | nil,
          parte: list() | nil
        }
end
