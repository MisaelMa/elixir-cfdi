defmodule Cfdi.Traslado do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Traslado"

  attribute :Base, :string
  attribute :Impuesto, :string
  attribute :TipoFactor, :string
  attribute :TasaOCuota, :string
  attribute :Importe, :string
end

defmodule Cfdi.Retencion do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Retencion"

  attribute :Base, :string
  attribute :Impuesto, :string
  attribute :TipoFactor, :string
  attribute :TasaOCuota, :string
  attribute :Importe, :string
end

defmodule Cfdi.Impuestos do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Impuestos", accepts_children: true

  attribute :TotalImpuestosTrasladados, :string
  attribute :TotalImpuestosRetenidos, :string

  child :traslados, :list
  child :retenciones, :list

  @doc """
  Adds a traslado to the global Impuestos block.
  """
  def add_traslado(i, %Cfdi.Traslado{} = t) when is_struct(i, __MODULE__) do
    list = (i.traslados || []) ++ [t]
    %{i | traslados: list}
  end

  def add_traslado(i, data) when is_struct(i, __MODULE__) and is_map(data) do
    add_traslado(i, struct(Cfdi.Traslado, data))
  end

  @doc """
  Adds a retención to the global Impuestos block.
  """
  def add_retencion(i, %Cfdi.Retencion{} = r) when is_struct(i, __MODULE__) do
    list = (i.retenciones || []) ++ [r]
    %{i | retenciones: list}
  end

  def add_retencion(i, data) when is_struct(i, __MODULE__) and is_map(data) do
    add_retencion(i, struct(Cfdi.Retencion, data))
  end

  @doc """
  Serializes the global `cfdi:Impuestos` block with its nested
  `cfdi:Retenciones` / `cfdi:Traslados` children. Returns `nil` when the
  block has no attributes and no children.
  """
  def to_element(nil), do: nil

  def to_element(i) when is_struct(i, __MODULE__) do
    traslados = i.traslados || []
    retenciones = i.retenciones || []

    total_trasl = Map.get(i, :TotalImpuestosTrasladados)
    total_ret = Map.get(i, :TotalImpuestosRetenidos)

    if is_nil(total_trasl) and is_nil(total_ret) and
         traslados == [] and retenciones == [] do
      nil
    else
      kids =
        [
          retenciones_block(retenciones),
          traslados_block(traslados)
        ]
        |> Enum.reject(&is_nil/1)

      XmlBuilder.element(
        {"cfdi:Impuestos", Cfdi.Xml.Element.__build_attrs__(i, __MODULE__), kids}
      )
    end
  end

  def to_element(data) when is_map(data) do
    to_element(struct(__MODULE__, data))
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
