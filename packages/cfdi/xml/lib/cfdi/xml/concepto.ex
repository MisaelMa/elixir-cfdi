defmodule Cfdi.Xml.Concepto do
  @moduledoc """
  Estructura de un concepto CFDI, espejo de la clase `Concepto` del
  paquete TypeScript.
  """

  alias Cfdi.Xml.{Catalogo, Impuestos}

  defstruct [
    :clave_prod_serv,
    :no_identificacion,
    :cantidad,
    :clave_unidad,
    :unidad,
    :descripcion,
    :valor_unitario,
    :importe,
    :descuento,
    :objeto_imp,
    :impuestos
  ]

  @type t :: %__MODULE__{
          clave_prod_serv: String.t() | nil,
          no_identificacion: String.t() | nil,
          cantidad: String.t() | number() | nil,
          clave_unidad: String.t() | nil,
          unidad: String.t() | nil,
          descripcion: String.t() | nil,
          valor_unitario: String.t() | number() | nil,
          importe: String.t() | number() | nil,
          descuento: String.t() | number() | nil,
          objeto_imp: Catalogo.t() | nil,
          impuestos: Impuestos.t() | nil
        }

  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    %__MODULE__{
      clave_prod_serv: fetch(data, "ClaveProdServ"),
      no_identificacion: fetch(data, "NoIdentificacion"),
      cantidad: fetch(data, "Cantidad"),
      clave_unidad: fetch(data, "ClaveUnidad"),
      unidad: fetch(data, "Unidad"),
      descripcion: fetch(data, "Descripcion"),
      valor_unitario: fetch(data, "ValorUnitario"),
      importe: fetch(data, "Importe"),
      descuento: fetch(data, "Descuento"),
      objeto_imp: Catalogo.new(fetch(data, "ObjetoImp"))
    }
  end

  @spec set_impuestos(t(), map()) :: t()
  def set_impuestos(%__MODULE__{} = concepto, data) when is_map(data) do
    %{concepto | impuestos: Impuestos.new(data)}
  end

  defp fetch(data, key) do
    case Map.fetch(data, key) do
      {:ok, value} -> value
      :error -> Map.get(data, String.to_atom(key))
    end
  end
end
