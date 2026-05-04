defmodule Cfdi.Concepto.Parte do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Parte", accepts_children: true

  alias Cfdi.Concepto.InformacionAduanera

  attribute :ClaveProdServ, :string
  attribute :NoIdentificacion, :string
  attribute :Cantidad, :string
  attribute :Unidad, :string
  attribute :Descripcion, :string
  attribute :ValorUnitario, :string
  attribute :Importe, :string

  child :informacion_aduanera, :list

  @doc """
  Añade un `cfdi:InformacionAduanera` a la parte.
  """
  def add_informacion_aduanera(p, %InformacionAduanera{} = ia) when is_struct(p, __MODULE__) do
    list = (p.informacion_aduanera || []) ++ [ia]
    %{p | informacion_aduanera: list}
  end

  def add_informacion_aduanera(p, pedimento) when is_struct(p, __MODULE__) and is_binary(pedimento) do
    add_informacion_aduanera(p, %InformacionAduanera{NumeroPedimento: pedimento})
  end

  def to_element(nil), do: nil

  def to_element(p) when is_struct(p, __MODULE__) do
    kids =
      (p.informacion_aduanera || [])
      |> Enum.map(&InformacionAduanera.to_element/1)
      |> Enum.reject(&is_nil/1)

    XmlBuilder.element({"cfdi:Parte", Cfdi.Xml.Element.__build_attrs__(p, __MODULE__), kids})
  end

  @doc false
  def to_map(nil, _opts), do: nil

  def to_map(p, opts) when is_struct(p, __MODULE__) and is_list(opts) do
    ns? = Keyword.get(opts, :ns, true)
    wrap? = Keyword.get(opts, :wrap, true)

    attrs =
      p
      |> Map.from_struct()
      |> Map.take(__xml__(:attributes))
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    body =
      case p.informacion_aduanera do
        nil ->
          attrs

        [] ->
          attrs

        list ->
          inner = Enum.map(list, &InformacionAduanera.to_map(&1, ns: ns?, wrap: false))
          key = if ns?, do: "cfdi:InformacionAduanera", else: "InformacionAduanera"
          Map.put(attrs, key, inner)
      end

    if wrap? do
      key = if ns?, do: "cfdi:Parte", else: "Parte"
      %{key => body}
    else
      body
    end
  end
end
