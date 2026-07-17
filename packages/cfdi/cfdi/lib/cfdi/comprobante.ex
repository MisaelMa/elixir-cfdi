defmodule Cfdi.Comprobante do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Comprobante", accepts_children: true
  alias Cfdi.{Concepto, Complemento, Relacionado, Impuestos, Emisor, Receptor, InformacionGlobal}
  alias Cfdi.Complementos.Tfd
  xmlns(:cfdi, "http://www.sat.gob.mx/cfd/4")
  xmlns(:xsi, "http://www.w3.org/2001/XMLSchema-instance")

  attribute(:Version, :string)
  attribute(:Serie, :string)
  attribute(:Folio, :string)
  attribute(:Fecha, :string)
  attribute(:FormaPago, :string)
  attribute(:CondicionesDePago, :string)
  attribute(:SubTotal, :string)
  attribute(:Descuento, :string)
  attribute(:Moneda, :string)
  attribute(:TipoCambio, :string)
  attribute(:Total, :string)
  attribute(:TipoDeComprobante, :string)
  attribute(:Exportacion, :string)
  attribute(:MetodoPago, :string)
  attribute(:LugarExpedicion, :string)
  attribute(:Confirmacion, :string)
  attribute(:NoCertificado, :string)
  attribute(:Certificado, :string)
  attribute(:Sello, :string)

  child(:"cfdi:Emisor", :map)
  child(:"cfdi:Receptor", :map)
  child(:"cfdi:Impuestos", :map)
  child(:"cfdi:InformacionGlobal", :map)
  child(:"cfdi:Conceptos", :list)
  child(:"cfdi:Complementos", :list)
  child(:"cfdi:CfdiRelacionados", :list)
  child(:"cfdi:Addenda", :map)
  child(:xmlns, :list)
  child(:schema_location, :string)

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
    c |> invalidar() |> Map.put(:"cfdi:Conceptos", list ++ [concepto])
  end

  def add_concepto(c, data) when is_map(data) do
    add_concepto(c, struct(Concepto, data))
  end

  def add_complemento(c, %Complemento{} = complemento) do
    list = Map.get(c, :"cfdi:Complementos") || []
    c |> invalidar() |> Map.put(:"cfdi:Complementos", list ++ [complemento])
  end

  def add_complemento(c, data) when is_map(data) do
    add_complemento(c, struct(Complemento, data))
  end

  def add_relacionado(c, %Relacionado{} = relacionado) do
    list = Map.get(c, :"cfdi:CfdiRelacionados") || []
    c |> invalidar() |> Map.put(:"cfdi:CfdiRelacionados", list ++ [relacionado])
  end

  def add_relacionado(c, data) when is_map(data) do
    add_relacionado(c, struct(Relacionado, data))
  end

  def add_impuesto(c, %Impuestos{} = impuesto) do
    c |> invalidar() |> Map.put(:"cfdi:Impuestos", impuesto)
  end

  def add_impuesto(c, data) when is_map(data) do
    add_impuesto(c, struct(Impuestos, data))
  end

  def add_emisor(c, %Emisor{} = emisor) do
    c |> invalidar() |> Map.put(:"cfdi:Emisor", emisor)
  end

  def add_emisor(c, data) when is_map(data) do
    add_emisor(c, struct(Emisor, data))
  end

  def add_receptor(c, %Receptor{} = receptor) do
    c |> invalidar() |> Map.put(:"cfdi:Receptor", receptor)
  end

  def add_receptor(c, data) when is_map(data) do
    add_receptor(c, struct(Receptor, data))
  end

  def add_informacion_global(c, %InformacionGlobal{} = informacion_global) do
    c |> invalidar() |> Map.put(:"cfdi:InformacionGlobal", informacion_global)
  end

  def add_informacion_global(c, data) when is_map(data) do
    add_informacion_global(c, struct(InformacionGlobal, data))
  end

  @doc """
  Establece la `cfdi:Addenda` — extensiones privadas del contribuyente.

  El XSD del SAT la declara como `<xs:any maxOccurs="unbounded"/>`: contenido
  arbitrario que el SAT no valida ni interpreta. Por eso la carga es un mapa
  opaco con la misma convención que el resto del árbol:

    * llave **átomo** (`:numero`) → atributo XML
    * llave **string** (`"proveedor:Pedido"`) → elemento hijo

  Ejemplo:

      Comprobante.set_addenda(comprobante, %{
        "proveedor:Pedido" => %{
          :"xmlns:proveedor" => "http://ejemplo.com/proveedor",
          :numero => "OC-4471",
          "proveedor:Comentarios" => "Entregar en almacén 3"
        }
      })

  Se emite como último hijo del comprobante, según el Anexo 20.

  ## La addenda no entra en la cadena original

  El XSLT oficial no la procesa, así que agregarla o cambiarla **no invalida
  el sello**: es lo único que se puede tocar en un CFDI ya timbrado. Pasar
  `nil` la elimina.
  """
  def set_addenda(c, nil), do: Map.put(c, :"cfdi:Addenda", nil)

  def set_addenda(c, addenda) when is_map(addenda) do
    Map.put(c, :"cfdi:Addenda", addenda)
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

  @doc """
  Invalida el sellado: borra el `Sello` y elimina el Timbre Fiscal Digital.

  Un CFDI timbrado es fiscalmente inmutable: su `Sello` y su timbre sólo son
  válidos para el contenido exacto que se selló. Los setters de contenido
  (`add_emisor/2`, `add_concepto/2`, …) llaman a esto solos, así que rara vez
  hace falta invocarlo a mano.

  Se necesita cuando modificás un atributo con la sintaxis de struct
  (`%{comp | Total: "…"}`), que no pasa por ningún setter y la librería no
  puede interceptar:

      comp = %{comp | Total: "999.00"} |> Comprobante.desellar()

  Después hay que volver a sellar (y re-timbrar) para tener un CFDI válido.
  No toca `Certificado`/`NoCertificado` — el re-sellado usa la misma
  credencial. Tampoco toca la `cfdi:Addenda`, que no entra en la cadena
  original.
  """
  @spec desellar(t()) :: t()
  def desellar(c) when is_struct(c, __MODULE__), do: invalidar(c)

  # Núcleo de la invalidación: sin `Sello` y sin TFD.
  #
  # Sobre un borrador sin sellar es un no-op efectivo (Sello ya es nil, no hay
  # TFD que quitar), así que es seguro llamarlo desde cada setter sin pensar en
  # si el comprobante ya venía timbrado.
  defp invalidar(c) do
    %{c | Sello: nil} |> quitar_tfd()
  end

  # Saca el `%Tfd{}` de cada `%Complemento{}`, conservando los demás
  # complementos (un PPD trae Pago20 + TFD: al invalidar, Pago20 sigue siendo
  # contenido válido, sólo el timbre muere). Los wrappers que quedan vacíos se
  # descartan.
  defp quitar_tfd(c) do
    case Map.get(c, :"cfdi:Complementos") do
      nil ->
        c

      complementos ->
        limpios =
          complementos
          |> Enum.map(fn %Complemento{children: children} = wrapper ->
            %{wrapper | children: Enum.reject(children || [], &is_struct(&1, Tfd))}
          end)
          |> Enum.reject(fn %Complemento{children: children} -> children == [] end)

        Map.put(c, :"cfdi:Complementos", empty_to_nil(limpios))
    end
  end

  defp empty_to_nil([]), do: nil
  defp empty_to_nil(list), do: list

  # Override: el macro expondría `:xmlns` y `:schema_location` como hijos,
  # pero son metadata del documento — no aparecen en la proyección a mapa.
  # Además, envolvemos `cfdi:Conceptos` con su hijo canónico `cfdi:Concepto` y
  # colapsamos la lista `cfdi:Complementos` en el tag singular `cfdi:Complemento`
  # que exige el Anexo 20 (un único nodo con todos los complementos como hijos).
  #
  # Los complementos se extraen ANTES del macro genérico porque cada
  # complemento concreto (Pago20, Nomina12, ...) implementa `get_complement/1`
  # con su propia key namespaced — la proyección genérica no la conoce.
  def to_map(c, opts) when is_struct(c, __MODULE__) and is_list(opts) do
    ns? = Keyword.get(opts, :ns, true)
    complementos_list = Map.get(c, :"cfdi:Complementos") || []

    c
    |> Map.put(:xmlns, nil)
    |> Map.put(:schema_location, nil)
    |> Map.put(:"cfdi:Complementos", nil)
    |> Cfdi.Xml.Element.__to_map__(__MODULE__, opts)
    |> wrap_conceptos(ns?)
    |> inject_complemento(complementos_list, ns?)
    |> inject_namespaces(c, ns?)
  end

  # Emite las declaraciones `xmlns:*` y el `xsi:schemaLocation` como atributos
  # de la raíz. Sin esto el XML no es namespace-well-formed y un PAC lo rechaza.
  #
  # La fuente son los campos `xmlns` / `schema_location` de la struct, que
  # `Cfdi.Decoder` llena con lo que traía el XML de origen — así el ida y vuelta
  # es fiel incluso cuando el documento original no declaraba nada. Para un
  # comprobante armado a mano (campo en `nil`) caemos a los namespaces que
  # declara el macro.
  #
  # Con `ns: false` no se emiten: esa proyección pide explícitamente una vista
  # plana sin información de namespace.
  defp inject_namespaces(map, _c, false), do: map

  defp inject_namespaces(map, c, true) do
    case Map.get(map, "cfdi:Comprobante") do
      nil -> map
      body -> Map.put(map, "cfdi:Comprobante", Map.merge(namespace_attrs(c), body))
    end
  end

  defp namespace_attrs(c) do
    declaraciones = c.xmlns || __xml__(:namespaces)
    attrs = Map.new(declaraciones, fn {prefix, uri} -> {ns_attr_key(prefix), uri} end)

    case c.schema_location do
      nil -> attrs
      loc -> Map.put(attrs, :"xsi:schemaLocation", loc)
    end
  end

  defp ns_attr_key(prefix) do
    case to_string(prefix) do
      "xmlns" -> :xmlns
      p -> :"xmlns:#{p}"
    end
  end

  defp wrap_conceptos(map, ns?) do
    root_key = if ns?, do: "cfdi:Comprobante", else: "Comprobante"
    conceptos_key = if ns?, do: "cfdi:Conceptos", else: "Conceptos"
    inner_key = if ns?, do: "cfdi:Concepto", else: "Concepto"

    case Map.get(map, root_key) do
      nil ->
        map

      body ->
        case Map.get(body, conceptos_key) do
          list when is_list(list) and list != [] ->
            new_body = Map.put(body, conceptos_key, %{inner_key => list})
            Map.put(map, root_key, new_body)

          _ ->
            map
        end
    end
  end

  # Colapsa la lista de wrappers `%Cfdi.Complemento{children: [...]}` en un
  # único nodo `cfdi:Complemento` cuyos hijos son los complementos concretos
  # (Pago20, Nomina12, etc.) indexados por su `key` namespaced.
  #
  # El SAT exige exactamente UN `<cfdi:Complemento>` por comprobante; cualquier
  # número de complementos concretos viven como hijos de ese nodo.
  defp inject_complemento(map, [], _ns?), do: map

  defp inject_complemento(map, complementos, ns?) do
    root_key = if ns?, do: "cfdi:Comprobante", else: "Comprobante"
    singular_key = if ns?, do: "cfdi:Complemento", else: "Complemento"

    case Map.get(map, root_key) do
      nil ->
        map

      body ->
        merged =
          complementos
          |> Enum.flat_map(fn
            %Complemento{children: children} -> children || []
            _ -> []
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.reduce(%{}, fn child, acc ->
            meta = child.__struct__.get_complement(child)
            Map.put(acc, meta.key, meta.complement)
          end)

        new_body =
          if map_size(merged) == 0, do: body, else: Map.put(body, singular_key, merged)

        Map.put(map, root_key, new_body)
    end
  end
end
