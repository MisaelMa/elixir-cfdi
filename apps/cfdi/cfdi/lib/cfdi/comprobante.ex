defmodule Cfdi.Comprobante do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Comprobante", accepts_children: true
  alias Cfdi.{Concepto, Complemento, Relacionado, Impuestos, Emisor, Receptor, InformacionGlobal}
  xmlns :cfdi, "http://www.sat.gob.mx/cfd/4"
  xmlns :xsi, "http://www.w3.org/2001/XMLSchema-instance"

  attribute :Version, :string
  attribute :Serie, :string
  attribute :Folio, :string
  attribute :Fecha, :string
  attribute :FormaPago, :string
  attribute :CondicionesDePago, :string
  attribute :SubTotal, :string
  attribute :Descuento, :string
  attribute :Moneda, :string
  attribute :TipoCambio, :string
  attribute :Total, :string
  attribute :TipoDeComprobante, :string
  attribute :Exportacion, :string
  attribute :MetodoPago, :string
  attribute :LugarExpedicion, :string
  attribute :Confirmacion, :string
  attribute :NoCertificado, :string
  attribute :Certificado, :string
  attribute :Sello, :string

  child :"cfdi:Emisor", :map
  child :"cfdi:Receptor", :map
  child :"cfdi:Impuestos", :map
  child :"cfdi:InformacionGlobal", :map
  child :"cfdi:Conceptos", :list
  child :"cfdi:Complementos", :list
  child :"cfdi:CfdiRelacionados", :list
  child :xmlns, :list
  child :schema_location, :string

  def xmlns() do
    [
      {:cfdi, "http://www.sat.gob.mx/cfd/4"},
      {:xsi, "http://www.w3.org/2001/XMLSchema-instance"}
    ]
  end

  def add_xmlns(c, xmlns) do
    %{c | xmlns: xmlns}
  end

  def add_schema_location(c, schema_location) do
    %{c | schema_location: schema_location}
  end


  def add_concepto(c, %Concepto{} = concepto) do
    list = Map.get(c, :"cfdi:Conceptos") || []
    Map.put(c, :"cfdi:Conceptos", list ++ [concepto])
  end

  def add_concepto(c, data) when is_map(data) do
    add_concepto(c, struct(Concepto, data))
  end

  def add_complemento(c, %Complemento{} = complemento) do
    list = Map.get(c, :"cfdi:Complementos") || []
    Map.put(c, :"cfdi:Complementos", list ++ [complemento])
  end

  def add_complemento(c, data) when is_map(data) do
    add_complemento(c, struct(Complemento, data))
  end

  def add_relacionado(c, %Relacionado{} = relacionado) do
    list = Map.get(c, :"cfdi:CfdiRelacionados") || []
    Map.put(c, :"cfdi:CfdiRelacionados", list ++ [relacionado])
  end

  def add_relacionado(c, data) when is_map(data) do
    add_relacionado(c, struct(Relacionado, data))
  end

  def add_impuesto(c, %Impuestos{} = impuesto) do
    Map.put(c, :"cfdi:Impuestos", impuesto)
  end

  def add_impuesto(c, data) when is_map(data) do
    add_impuesto(c, struct(Impuestos, data))
  end

  def add_emisor(c, %Emisor{} = emisor) do
    Map.put(c, :"cfdi:Emisor", emisor)
  end

  def add_emisor(c, data) when is_map(data) do
    add_emisor(c, struct(Emisor, data))
  end

  def add_receptor(c, %Receptor{} = receptor) do
    Map.put(c, :"cfdi:Receptor", receptor)
  end

  def add_receptor(c, data) when is_map(data) do
    add_receptor(c, struct(Receptor, data))
  end

  def add_informacion_global(c, %InformacionGlobal{} = informacion_global) do
    Map.put(c, :"cfdi:InformacionGlobal", informacion_global)
  end

  def add_informacion_global(c, data) when is_map(data) do
    add_informacion_global(c, struct(InformacionGlobal, data))
  end

  def set_certificado(c, certificado) when is_binary(certificado) do
    %{c | Certificado: certificado}
  end

  def set_no_certificado(c, no_certificado) when is_binary(no_certificado) do
    %{c | NoCertificado: no_certificado}
  end

  def set_sello(c, sello) when is_binary(sello) do
    %{c | Sello: sello}
  end

  # Override: el macro expondría `:xmlns` y `:schema_location` como hijos,
  # pero son metadata del documento — no aparecen en la proyección a mapa.
  def to_map(c, opts) when is_struct(c, __MODULE__) and is_list(opts) do
    c
    |> Map.put(:xmlns, nil)
    |> Map.put(:schema_location, nil)
    |> Cfdi.Xml.Element.__to_map__(__MODULE__, opts)
  end
end
