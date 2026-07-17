defmodule Cfdi.Decoder do
  @moduledoc """
  Decodifica un XML CFDI 4.0 a un `%Cfdi.Comprobante{}` completo.

  Es el camino inverso de `CFDI.to_xml/2`. La API pública vive en
  `CFDI.from_xml/2` y `CFDI.from_file/2`; este módulo es el motor.

  ## Por qué no reusa `Cfdi.Xml.Parser`

  `Cfdi.Xml.Parser` produce un mapa **de lectura**: aplana todo a llaves del
  mismo tipo y adivina la pluralización por heurística de nombres. Eso sirve
  para inspeccionar un CFDI, no para reconstruirlo.

  La serialización (`CFDI.to_xml/2`) se apoya en una convención estricta:

    * llave **átomo** (`:Version`) → atributo XML
    * llave **string** (`"cfdi:Emisor"`) → elemento hijo

  Este decoder respeta esa convención y toma la forma de cada elemento del
  DSL (`Cfdi.Xml.Element.__xml__/1`), que es la fuente de verdad de qué es
  atributo y qué es hijo. Por eso `from_xml |> to_xml` roundtrippea.

  ## Namespaces

  La resolución de complementos va por la **URI** del namespace, con
  herencia de scope: un `xmlns:foo` declarado en la raíz aplica a los
  descendientes. Un CFDI puede declarar el namespace del complemento en la
  raíz (`vehiculo_usado.xml`) o en el propio elemento (`cfdi-completo.xml`);
  ambos casos se resuelven igual. El prefijo es irrelevante — ver
  `Cfdi.Complementos.Complemento`.
  """

  alias Cfdi.{
    Comprobante,
    Complemento,
    Concepto,
    Emisor,
    Impuestos,
    InformacionGlobal,
    Receptor,
    Relacionado,
    Retencion,
    Traslado
  }

  alias Cfdi.Concepto.{ACuentaTerceros, CuentaPredial, InformacionAduanera, Parte}
  alias Cfdi.Complementos.Registry

  @type reason ::
          {:malformed_xml, term()}
          | {:unexpected_root, String.t()}

  @doc """
  Decodifica un XML CFDI a `%Cfdi.Comprobante{}`.
  """
  @spec decode(String.t()) :: {:ok, Comprobante.t()} | {:error, reason()}
  def decode(xml) when is_binary(xml) do
    case Saxy.SimpleForm.parse_string(xml) do
      {:ok, root} -> decode_root(root)
      {:error, reason} -> {:error, {:malformed_xml, reason}}
    end
  end

  defp decode_root({name, attrs, children} = root) do
    case local(name) do
      "Comprobante" -> {:ok, build_comprobante(root, ns_env(attrs, %{}), children)}
      _ -> {:error, {:unexpected_root, name}}
    end
  end

  defp build_comprobante({_name, attrs, _}, env, children) do
    {ns_attrs, plain_attrs} = split_ns_attrs(attrs)

    Comprobante
    |> struct(decode_attrs(Comprobante, plain_attrs))
    |> Map.put(:xmlns, ns_attrs)
    |> Map.put(:schema_location, schema_location(attrs))
    |> put_children(elements(children), env)
  end

  defp put_children(comprobante, elements, env) do
    Enum.reduce(elements, comprobante, fn {name, _, _} = el, acc ->
      case local(name) do
        "Emisor" -> Map.put(acc, :"cfdi:Emisor", simple(Emisor, el))
        "Receptor" -> Map.put(acc, :"cfdi:Receptor", simple(Receptor, el))
        "InformacionGlobal" -> Map.put(acc, :"cfdi:InformacionGlobal", simple(InformacionGlobal, el))
        "Impuestos" -> Map.put(acc, :"cfdi:Impuestos", decode_impuestos(el))
        "Conceptos" -> Map.put(acc, :"cfdi:Conceptos", decode_conceptos(el, env))
        "CfdiRelacionados" -> append(acc, :"cfdi:CfdiRelacionados", decode_relacionados(el))
        "Complemento" -> append(acc, :"cfdi:Complementos", decode_complemento(el, env))
        "Addenda" -> Map.put(acc, :"cfdi:Addenda", decode_opaque(el))
        _ -> acc
      end
    end)
  end

  defp append(struct, key, value) do
    Map.put(struct, key, (Map.get(struct, key) || []) ++ [value])
  end

  # ---------------------------------------------------------------------------
  # Conceptos
  # ---------------------------------------------------------------------------

  defp decode_conceptos({_, _, children}, env) do
    children
    |> elements()
    |> Enum.filter(&(local(elem(&1, 0)) == "Concepto"))
    |> Enum.map(&decode_concepto(&1, env))
  end

  defp decode_concepto({_, attrs, children}, env) do
    base = struct(Concepto, decode_attrs(Concepto, attrs))

    children
    |> elements()
    |> Enum.reduce(base, fn {name, _, _} = el, acc ->
      case local(name) do
        "Impuestos" ->
          impuestos = decode_impuestos(el)
          %{acc | traslados: impuestos.traslados, retenciones: impuestos.retenciones}

        "ACuentaTerceros" ->
          %{acc | a_cuenta_terceros: simple(ACuentaTerceros, el)}

        "CuentaPredial" ->
          %{acc | cuenta_predial: simple(CuentaPredial, el)}

        "InformacionAduanera" ->
          %{acc | informacion_aduanera: (acc.informacion_aduanera || []) ++ [simple(InformacionAduanera, el)]}

        "Parte" ->
          %{acc | parte: (acc.parte || []) ++ [decode_parte(el)]}

        "ComplementoConcepto" ->
          %{acc | complemento: decode_complemento_concepto(el, env)}

        _ ->
          acc
      end
    end)
  end

  defp decode_parte({_, attrs, children}) do
    aduana =
      children
      |> elements()
      |> Enum.filter(&(local(elem(&1, 0)) == "InformacionAduanera"))
      |> Enum.map(&simple(InformacionAduanera, &1))

    Parte
    |> struct(decode_attrs(Parte, attrs))
    |> Map.put(:informacion_aduanera, empty_to_nil(aduana))
  end

  # ---------------------------------------------------------------------------
  # Impuestos — mismo shape a nivel comprobante y a nivel concepto
  # ---------------------------------------------------------------------------

  defp decode_impuestos({_, attrs, children}) do
    els = elements(children)

    Impuestos
    |> struct(decode_attrs(Impuestos, attrs))
    |> Map.put(:traslados, collect(els, "Traslados", "Traslado", Traslado))
    |> Map.put(:retenciones, collect(els, "Retenciones", "Retencion", Retencion))
  end

  # `<cfdi:Traslados><cfdi:Traslado …/></cfdi:Traslados>` → [%Traslado{}]
  defp collect(elements, wrapper, inner, module) do
    elements
    |> Enum.filter(&(local(elem(&1, 0)) == wrapper))
    |> Enum.flat_map(fn {_, _, kids} -> elements(kids) end)
    |> Enum.filter(&(local(elem(&1, 0)) == inner))
    |> Enum.map(&simple(module, &1))
    |> empty_to_nil()
  end

  # ---------------------------------------------------------------------------
  # CfdiRelacionados
  # ---------------------------------------------------------------------------

  defp decode_relacionados({_, attrs, children}) do
    uuids =
      children
      |> elements()
      |> Enum.filter(&(local(elem(&1, 0)) == "CfdiRelacionado"))
      |> Enum.map(&simple(Relacionado.CfdiRelacionado, &1))

    Relacionado
    |> struct(decode_attrs(Relacionado, attrs))
    |> Map.put(:"cfdi:CfdiRelacionado", empty_to_nil(uuids))
  end

  # ---------------------------------------------------------------------------
  # Complementos
  # ---------------------------------------------------------------------------

  defp decode_complemento({_, attrs, children}, env) do
    env = ns_env(attrs, env)

    kids =
      children
      |> elements()
      |> Enum.map(&resolve_complemento(&1, env))

    %Complemento{children: kids}
  end

  defp decode_complemento_concepto({_, attrs, children}, env) do
    env = ns_env(attrs, env)

    kids =
      children
      |> elements()
      |> Enum.map(&resolve_complemento(&1, env))

    %Cfdi.Concepto.Complemento{complementos: kids}
  end

  # Resuelve el módulo por la URI del namespace y le entrega el subárbol como
  # `data` opaca. Un complemento que no está en el Registry NO se descarta: cae
  # al struct genérico `Cfdi.Complementos.Complemento`, que preserva key/xmlns y
  # carga útil. Descartarlo sería perder datos fiscales en silencio.
  defp resolve_complemento({name, attrs, _} = el, env) do
    data = decode_opaque(el)
    uri = resolve_uri(name, ns_env(attrs, env))

    case uri && Registry.by_xmlns(uri) do
      nil -> %Cfdi.Complementos.Complemento{key: name, xmlns: uri, data: data}
      module -> module.new(data)
    end
  end

  # Subárbol opaco → cuerpo con la convención átomo=atributo / string=elemento,
  # la misma que usa `CFDI.to_xml/2` para reconstruir. Se usa para las cargas
  # que la librería no modela: complementos y `cfdi:Addenda`.
  #
  # Las declaraciones `xmlns:*` que estén EN el elemento se conservan como
  # atributos: son parte de lo que hay que volver a emitir.
  #
  # Una hoja de solo texto (`<Comentarios>algo</Comentarios>`) devuelve el
  # string pelado, no un mapa: `to_element/2` distingue mapa (atributos+hijos)
  # de escalar (nodo de texto). Envolverlo en `%{text: "algo"}` lo emitiría
  # como el atributo `text="algo"` — mal.
  defp decode_opaque({_name, attrs, children}) do
    attr_map = Map.new(attrs, fn {k, v} -> {String.to_atom(k), v} end)
    els = elements(children)

    child_map =
      els
      |> Enum.group_by(&elem(&1, 0))
      |> Map.new(fn {name, group} -> {name, unwrap_single(Enum.map(group, &decode_opaque/1))} end)

    cond do
      map_size(attr_map) == 0 and map_size(child_map) == 0 ->
        text(children)

      true ->
        attr_map
        |> Map.merge(child_map)
        |> put_order(els)
    end
  end

  # Un mapa no puede expresar orden: los mapas chicos de Elixir iteran ordenados
  # por término, no por inserción. Pero el XSD del SAT declara `<xs:sequence>` —
  # emitir `<pago20:Pago>` antes de `<pago20:Totales>` produce XML que el PAC
  # rechaza. Guardamos el orden documental en `:__order__` para que
  # `CFDI.to_xml/2` lo respete al reconstruir.
  #
  # Sólo cuando hay 2+ nombres de hijo distintos: con 0 o 1 el orden es
  # irrelevante y la llave sería ruido (la mayoría de los complementos son
  # planos y no la llevan).
  defp put_order(body, els) do
    case els |> Enum.map(&elem(&1, 0)) |> Enum.uniq() do
      names when length(names) > 1 -> Map.put(body, :__order__, names)
      _ -> body
    end
  end

  defp unwrap_single([single]), do: single
  defp unwrap_single(many), do: many

  # ---------------------------------------------------------------------------
  # Namespaces
  # ---------------------------------------------------------------------------

  # Acumula las declaraciones xmlns visibles, heredando el scope del padre.
  defp ns_env(attrs, parent) do
    Enum.reduce(attrs, parent, fn
      {"xmlns", uri}, env -> Map.put(env, :default, uri)
      {"xmlns:" <> prefix, uri}, env -> Map.put(env, prefix, uri)
      _, env -> env
    end)
  end

  defp resolve_uri(name, env) do
    case String.split(name, ":", parts: 2) do
      [prefix, _local] -> Map.get(env, prefix)
      [_local] -> Map.get(env, :default)
    end
  end

  # Separa las declaraciones de namespace del resto de los atributos.
  # Devuelve `[{prefijo, uri}]` — lista, no mapa, para preservar el orden.
  defp split_ns_attrs(attrs) do
    {ns, plain} =
      Enum.split_with(attrs, fn {k, _} ->
        k == "xmlns" or String.starts_with?(k, "xmlns:")
      end)

    declarations =
      Enum.map(ns, fn
        {"xmlns", uri} -> {"xmlns", uri}
        {"xmlns:" <> prefix, uri} -> {prefix, uri}
      end)

    {declarations, plain}
  end

  defp schema_location(attrs) do
    Enum.find_value(attrs, fn {k, v} ->
      if local(k) == "schemaLocation", do: v
    end)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Elemento sin hijos: sólo atributos declarados en el DSL.
  defp simple(module, {_, attrs, _}), do: struct(module, decode_attrs(module, attrs))

  # Toma únicamente los atributos que el DSL declara. Los desconocidos se
  # ignoran; los nombres se convierten con `to_existing_atom` porque ya sabemos
  # que el átomo existe (lo creó el `defstruct` del macro). Nunca creamos átomos
  # a partir de nombres arbitrarios del XML acá.
  defp decode_attrs(module, attrs) do
    declared = MapSet.new(module.__xml__(:attributes), &Atom.to_string/1)

    attrs
    |> Enum.filter(fn {k, _} -> MapSet.member?(declared, k) end)
    |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
  end

  defp elements(children), do: Enum.filter(children, &match?({_, _, _}, &1))

  defp text(children) do
    children
    |> Enum.filter(&is_binary/1)
    |> Enum.join()
    |> String.trim()
  end

  defp local(name) do
    case String.split(name, ":", parts: 2) do
      [_prefix, local] -> local
      [local] -> local
    end
  end

  defp empty_to_nil([]), do: nil
  defp empty_to_nil(list), do: list
end
