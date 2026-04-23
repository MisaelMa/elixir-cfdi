defmodule Cfdi.Concepto do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Concepto", accepts_children: true

  attribute :ClaveProdServ, :string
  attribute :NoIdentificacion, :string
  attribute :Cantidad, :string
  attribute :ClaveUnidad, :string
  attribute :Unidad, :string
  attribute :Descripcion, :string
  attribute :ValorUnitario, :string
  attribute :Importe, :string
  attribute :Descuento, :string
  attribute :ObjetoImp, :string

  child :traslados, :list
  child :retenciones, :list
  child :informacion_aduanera, :list
  child :cuenta_predial, :list
  child :parte, :list

  @doc """
  Adds a traslado to the concept. Accepts a map or `Cfdi.Traslado` struct.
  """
  def add_traslado(c, %Cfdi.Traslado{} = t) when is_struct(c, __MODULE__) do
    list = (c.traslados || []) ++ [t]
    %{c | traslados: list}
  end

  def add_traslado(c, data) when is_struct(c, __MODULE__) and is_map(data) do
    add_traslado(c, struct(Cfdi.Traslado, data))
  end

  @doc """
  Adds a retención to the concept. Accepts a map or `Cfdi.Retencion` struct.
  """
  def add_retencion(c, %Cfdi.Retencion{} = r) when is_struct(c, __MODULE__) do
    list = (c.retenciones || []) ++ [r]
    %{c | retenciones: list}
  end

  def add_retencion(c, data) when is_struct(c, __MODULE__) and is_map(data) do
    add_retencion(c, struct(Cfdi.Retencion, data))
  end

  @doc """
  Serializes a `Cfdi.Concepto` to the proper XML tuple, including its
  nested `cfdi:Impuestos` block when traslados or retenciones are present.

  This overrides the auto-generated `to_element/1` from the macro so we
  can inject the nested impuestos structure.
  """
  def to_element(nil), do: nil

  def to_element(c) when is_struct(c, __MODULE__) do
    impuestos = impuestos_element(c)
    kids = [impuestos] |> Enum.reject(&is_nil/1)

    XmlBuilder.element(
      {"cfdi:Concepto", Cfdi.Xml.Element.__build_attrs__(c, __MODULE__), kids}
    )
  end

  @doc """
  Builds a `<cfdi:Conceptos>` block wrapping many `Cfdi.Concepto` elements.
  """
  def conceptos_block([]), do: nil

  def conceptos_block(conceptos) when is_list(conceptos) do
    kids = Enum.map(conceptos, &to_element/1)
    XmlBuilder.element({"cfdi:Conceptos", %{}, kids})
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp impuestos_element(c) when is_struct(c, __MODULE__) do
    t = c.traslados || []
    r = c.retenciones || []

    cond do
      t == [] and r == [] ->
        nil

      true ->
        kids =
          [
            traslados_block(t),
            retenciones_block(r)
          ]
          |> Enum.reject(&is_nil/1)

        XmlBuilder.element({"cfdi:Impuestos", %{}, kids})
    end
  end

  defp traslados_block([]), do: nil

  defp traslados_block(list) when is_list(list) do
    kids = Enum.map(list, &Cfdi.Traslado.to_element/1)
    XmlBuilder.element({"cfdi:Traslados", %{}, kids})
  end

  defp retenciones_block([]), do: nil

  defp retenciones_block(list) when is_list(list) do
    kids = Enum.map(list, &Cfdi.Retencion.to_element/1)
    XmlBuilder.element({"cfdi:Retenciones", %{}, kids})
  end
end
