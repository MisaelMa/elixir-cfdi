defmodule CFDI do
  @moduledoc """
  Orquestador principal del CFDI 4.0.

  Recibe un `%Cfdi.Comprobante{}` previamente armado con sus elementos
  (`Emisor`, `Receptor`, `Conceptos`, …), lo certifica, sella y serializa
  a XML, mapa o JSON.
  """

  alias Cfdi.Comprobante
  alias Cfdi.Decoder
  alias Cfdi.Transform.Transform
  alias Sat.Certificados.{Certificate, Credential, PrivateKey}

  defstruct comprobante: nil, config: %{}

  @type t :: %__MODULE__{
          comprobante: Comprobante.t() | nil,
          config: map()
        }

  @spec new(Comprobante.t()) :: t()
  def new(%Comprobante{} = comprobante), do: %__MODULE__{comprobante: comprobante}

  @doc """
  Reconstruye un `%CFDI{}` completo a partir de un XML.

  Camino inverso de `to_xml/2`: devuelve el comprobante con todo lo que traía
  el documento —emisor, receptor, información global, conceptos con sus
  impuestos y complementos de concepto, impuestos globales, CFDI relacionados
  y complementos— como structs tipados, listo para inspeccionar o modificar.

      {:ok, cfdi} = CFDI.from_xml(xml)
      cfdi.comprobante."Total"
      cfdi.comprobante |> Map.get(:"cfdi:Emisor") |> Map.get(:Rfc)

  Los complementos se resuelven por la URI de su namespace contra
  `Cfdi.Complementos.Registry`. Uno desconocido no se descarta: cae al struct
  genérico `Cfdi.Complementos.Complemento`, preservando su carga útil.

  ## Cuidado: un CFDI timbrado es inmutable

  `from_xml/2` preserva `Sello`, `Certificado`, `NoCertificado` y el
  `TimbreFiscalDigital` tal como venían — `to_xml/2` los devuelve intactos.

  Pero **modificar un comprobante timbrado invalida su sello**: la cadena
  original deja de coincidir. Fiscalmente eso no es "editar" una factura, es
  emitir otra: hay que volver a sellar (`sellar/3`) y re-timbrar, lo que
  produce un folio fiscal nuevo. Usá `timbrado?/1` antes de tocar nada.

  ## Errores

    * `{:error, {:malformed_xml, reason}}` — el XML no parsea
    * `{:error, {:unexpected_root, name}}` — la raíz no es `cfdi:Comprobante`
  """
  @spec from_xml(String.t(), keyword()) :: {:ok, t()} | {:error, Decoder.reason()}
  def from_xml(xml, opts \\ []) when is_binary(xml) and is_list(opts) do
    case Decoder.decode(xml) do
      {:ok, comprobante} -> {:ok, %__MODULE__{comprobante: comprobante}}
      {:error, _} = error -> error
    end
  end

  @doc """
  Igual que `from_xml/2` pero leyendo desde disco.

  Agrega `{:error, {:file_error, posix}}` a los errores posibles.
  """
  @spec from_file(Path.t(), keyword()) ::
          {:ok, t()} | {:error, Decoder.reason() | {:file_error, File.posix()}}
  def from_file(path, opts \\ []) when is_binary(path) and is_list(opts) do
    case File.read(path) do
      {:ok, xml} -> from_xml(xml, opts)
      {:error, reason} -> {:error, {:file_error, reason}}
    end
  end

  @doc """
  Igual que `from_xml/2` pero devuelve el `%CFDI{}` directo o levanta.
  """
  @spec from_xml!(String.t(), keyword()) :: t()
  def from_xml!(xml, opts \\ []) do
    case from_xml(xml, opts) do
      {:ok, cfdi} ->
        cfdi

      {:error, reason} ->
        raise ArgumentError, "no se pudo decodificar el CFDI: #{inspect(reason)}"
    end
  end

  @doc """
  Igual que `from_file/2` pero devuelve el `%CFDI{}` directo o levanta.
  """
  @spec from_file!(Path.t(), keyword()) :: t()
  def from_file!(path, opts \\ []) do
    case from_file(path, opts) do
      {:ok, cfdi} -> cfdi
      {:error, reason} -> raise ArgumentError, "no se pudo leer el CFDI: #{inspect(reason)}"
    end
  end

  @doc """
  ¿El comprobante trae Timbre Fiscal Digital?

  Un CFDI timbrado ya fue certificado por un PAC: su `Sello` y su UUID sólo
  son válidos para el contenido exacto que se timbró. Modificar el contenido
  lo invalida — los setters de contenido borran el `Sello` y el timbre. Ver
  `from_xml/2` y `desellar/1`.
  """
  @spec timbrado?(t()) :: boolean()
  def timbrado?(%__MODULE__{} = cfdi), do: not is_nil(tfd(cfdi))

  @doc """
  ¿El comprobante está sellado (tiene `Sello`)?

  Sellado y timbrado son etapas distintas: primero el emisor sella con su CSD,
  después el PAC timbra. Un CFDI recién sellado está `sellado?` pero todavía no
  `timbrado?`.
  """
  @spec sellado?(t()) :: boolean()
  def sellado?(%__MODULE__{comprobante: nil}), do: false
  def sellado?(%__MODULE__{comprobante: comp}), do: not is_nil(comp."Sello")

  @doc """
  Invalida el sellado del documento: borra el `Sello` y el Timbre Fiscal
  Digital, dejándolo listo para volver a sellar.

  Atajo de `Cfdi.Comprobante.desellar/1` al nivel del `%CFDI{}`. Ver ahí
  cuándo hace falta llamarlo a mano.
  """
  @spec desellar(t()) :: t()
  def desellar(%__MODULE__{comprobante: nil} = cfdi), do: cfdi

  def desellar(%__MODULE__{comprobante: comp} = cfdi),
    do: %{cfdi | comprobante: Comprobante.desellar(comp)}

  @doc """
  Folio fiscal (UUID) del timbre, o `nil` si el comprobante no está timbrado.
  """
  @spec uuid(t()) :: String.t() | nil
  def uuid(%__MODULE__{} = cfdi) do
    case tfd(cfdi) do
      nil -> nil
      %{data: data} when is_map(data) -> Map.get(data, :UUID)
      _ -> nil
    end
  end

  defp tfd(%__MODULE__{comprobante: nil}), do: nil

  defp tfd(%__MODULE__{comprobante: comprobante}) do
    (Map.get(comprobante, :"cfdi:Complementos") || [])
    |> Enum.flat_map(fn
      %Cfdi.Complemento{children: children} -> children || []
      _ -> []
    end)
    |> Enum.find(&is_struct(&1, Cfdi.Complementos.Tfd))
  end

  @doc """
  Asocia certificado y número de certificado al comprobante.

  La opción `:formato_no_certificado` controla qué valor se escribe en
  `NoCertificado`:

    * `:sat` (default) — número de 20 dígitos que exige el anexo 20
      (`Credential.no_certificado/1`). Es el formato válido para timbrado.
    * `:serie` — número de serie del certificado en hexadecimal
      (`Credential.serial_number/1`). Variante para consumidores que
      requieran el serial crudo; **no** es válido en el atributo `NoCertificado`
      de un CFDI para el SAT.
  """
  @spec certificar(t(), Credential.t(), keyword()) :: {:ok, t()} | {:error, atom()}
  def certificar(cfdi, cred, opts \\ [])

  def certificar(%__MODULE__{comprobante: comp} = c, %Credential{} = cred, opts) do
    no_certificado =
      case Keyword.get(opts, :formato_no_certificado, :sat) do
        :sat -> Credential.no_certificado(cred)
        :serie -> Credential.serial_number(cred)
      end

    updated =
      struct(comp, %{
        Certificado: Certificate.to_base64(cred.certificate),
        NoCertificado: no_certificado
      })

    {:ok, %{c | comprobante: updated, config: Map.put(c.config, :credential, cred)}}
  end

  def certificar(%__MODULE__{}, _, _), do: {:error, :credential_must_be_credential_struct}

  @doc """
  Asocia la ruta del XSLT que generará la cadena original.

  Espejo de `options.xslt` en el constructor de
  [`CFDI`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/xml/src/cfdi.ts#L29) de Node.
  """
  @spec xslt(t(), String.t()) :: t()
  def xslt(%__MODULE__{} = c, path) when is_binary(path),
    do: %{c | config: Map.put(c.config, :xslt, path)}

  @doc """
  Genera la cadena original aplicando el XSLT al XML del CFDI.

  Espejo de [`generarCadenaOriginal`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/xml/src/cfdi.ts#L115)
  de Node. Toma el XSLT desde `config[:xslt]` (set vía `xslt/2`) o desde
  `opts[:xslt]`.
  """
  @spec generar_cadena_original(t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def generar_cadena_original(%__MODULE__{} = c, opts \\ []) do
    xslt_path = Keyword.get(opts, :xslt) || Map.get(c.config, :xslt)

    cond do
      is_nil(xslt_path) ->
        {:error, :missing_xslt}

      not File.exists?(xslt_path) ->
        {:error, {:xslt_not_found, xslt_path}}

      true ->
        xml = to_xml(c)

        Transform.new()
        |> Transform.xml_string(xml)
        |> Transform.xsl(xslt_path)
        |> Transform.run()
    end
  end

  @doc """
  Firma la cadena original con la llave privada cargada desde archivo.

  Espejo de [`generarSello`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/xml/src/cfdi.ts#L173)
  de Node.
  """
  @spec generar_sello(String.t(), Path.t(), String.t() | nil) ::
          {:ok, String.t()} | {:error, term()}
  def generar_sello(cadena, keyfile, password \\ nil)
      when is_binary(cadena) and is_binary(keyfile) do
    case PrivateKey.from_file(keyfile, password) do
      {:ok, pk} -> {:ok, PrivateKey.sign(pk, cadena)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Firma la cadena original y escribe el atributo `Sello` usando una credencial
  ya cargada en `config[:credential]` y la cadena en `config[:cadena]`.

  Para el flujo de alto nivel desde archivos, usar `sellar/3`.
  """
  @spec sellar(t()) :: {:ok, t()} | {:error, atom()}
  def sellar(%__MODULE__{comprobante: comp, config: cfg} = c) do
    cadena = Map.get(cfg, :cadena) || Map.get(cfg, "cadena")
    cred = Map.get(cfg, :credential)

    cond do
      is_nil(cadena) ->
        {:error, :missing_cadena}

      is_nil(cred) ->
        {:error, :missing_credential}

      true ->
        sello = Credential.sign(cred, cadena)
        {:ok, %{c | comprobante: struct(comp, %{Sello: sello})}}
    end
  end

  @doc """
  Genera la cadena original, la firma con la llave privada del archivo dado,
  guarda la cadena en `config[:cadena_original]` y escribe el atributo `Sello`.

  Espejo de [`sellar(keyfile, password)`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/xml/src/cfdi.ts#L68)
  de Node:

      public async sellar(keyfile: string, password: string): Promise<void> {
        const cadena = await this.generarCadenaOriginal();
        const sello = await this.generarSello(cadena, keyfile, password);
        this._cadenaOriginal = cadena;
        this.setSello(sello);
      }
  """
  @spec sellar(t(), Path.t(), String.t() | nil) :: {:ok, t()} | {:error, term()}
  def sellar(%__MODULE__{comprobante: comp} = c, keyfile, password)
      when is_binary(keyfile) do
    with {:ok, cadena} <- generar_cadena_original(c),
         {:ok, sello} <- generar_sello(cadena, keyfile, password) do
      updated_comp = Comprobante.set_sello(comp, sello)
      new_config = Map.put(c.config, :cadena_original, cadena)
      {:ok, %{c | comprobante: updated_comp, config: new_config}}
    end
  end

  def sellar(%__MODULE__{} = c, %Sat.Certificados.Credential{} = credential) do
    with {:ok, cadena} <- generar_cadena_original(c) do
      sello = Credential.sign(credential, cadena)
      updated_comp = Comprobante.set_sello(c.comprobante, sello)
      new_config = Map.put(c.config, :cadena_original, cadena)
      {:ok, %{c | comprobante: updated_comp, config: new_config}}
    end
  end

  @doc """
  Devuelve la cadena original guardada por `sellar/3`, o `nil` si todavía no
  fue sellado.

  Espejo del getter [`cadenaOriginal`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/xml/src/cfdi.ts#L196)
  de Node.
  """
  @spec cadena_original(t()) :: String.t() | nil
  def cadena_original(%__MODULE__{config: cfg}), do: Map.get(cfg, :cadena_original)

  @doc """
  Proyecta el CFDI a un mapa de **datos**.

  Las declaraciones de namespace (`xmlns:*`) y el `xsi:schemaLocation` NO
  aparecen: son plomería para reconstruir el XML, no datos del comprobante, y
  viven sólo en el camino de `to_xml/2`. El mapa trae emisor, receptor,
  conceptos, impuestos, sello, complementos… sin ruido de XML. Lo mismo aplica
  al JSON de `to_json/2`, que se arma sobre este mapa.

  Opciones:
    * `:ns` — `true` (default) incluye el prefijo `cfdi:` en los nombres de
      elementos y mantiene los atributos como átomos (`:Rfc`, `:Nombre`)
      para distinguirlos de los elementos hijos; `false` los omite y
      uniforma TODAS las llaves al tipo elegido en `:keys`.

    * `:keys` — controla el tipo de las llaves cuando `ns: false`. Sin efecto
      con `ns: true` (la convención manda). Valores:
        * `:string` (default) — todas las llaves son strings. Siempre seguro.
        * `:existing` — llaves se convierten a átomo si ya existe en la
          tabla global de átomos del VM; si no, quedan como string. Seguro
          ante XML/llaves arbitrarias.
        * `:atom` — todas las llaves se convierten a átomos vía
          `String.to_atom/1`. **Peligroso** con XML externo: la tabla de
          átomos no tiene GC y puede agotarse (`atom_table_full`). Usar
          solo cuando se controla la fuente del XML.

    * `:case` — controla la capitalización de las llaves cuando `ns: false`.
      Sin efecto con `ns: true`. Valores:
        * `:as_is` (default) — preserva la capitalización original (PascalCase
          como en el XSD oficial: `NoCertificado`, `RegimenFiscal`).
        * `:camel` — pasa la primera letra a minúscula para producir
          camelCase idiomático (`noCertificado`, `regimenFiscal`). El resto
          del nombre queda intacto (`UsoCFDI` → `usoCFDI`, preservando el
          acrónimo final). Útil al exportar a JSON o sistemas JS que
          esperan camelCase.

  Convenciones de llaves cuando `ns: true`:
    * strings (`"cfdi:Emisor"`) son elementos XML.
    * átomos (`:Rfc`, `:Nombre`) son atributos XML.

  Cuando `ns: false`, las llaves se uniforman para una vista plana — útil
  para inspección, serialización a JSON o consumo desde sistemas que no
  distinguen entre atributos y elementos.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = cfdi), do: to_map(cfdi, [])

  @spec to_map(t(), keyword()) :: map()
  def to_map(%__MODULE__{} = cfdi, opts) when is_list(opts) do
    # `to_map` proyecta DATOS. Las declaraciones de namespace (`xmlns:*`,
    # `xsi:schemaLocation`) y el orden (`:__order__`) son metadata para
    # reconstruir el XML, no datos del CFDI: viven sólo en `to_internal_map/2`
    # (el camino de `to_xml/2`, que sí los necesita) y se limpian acá. Así el
    # mapa —y el JSON que sale de él— trae emisor, receptor, conceptos, sello,
    # complementos… sin plomería de XML.
    base = cfdi |> to_internal_map(opts) |> strip_xml_meta()

    if Keyword.get(opts, :ns, true) do
      base
    else
      keys_mode = Keyword.get(opts, :keys, :string)
      case_mode = Keyword.get(opts, :case, :as_is)
      transform_keys(base, key_transformer(keys_mode, case_mode))
    end
  end

  defp strip_xml_meta(map) when is_map(map) do
    map
    |> Enum.reject(fn {k, _} -> xml_meta_key?(k) end)
    |> Map.new(fn {k, v} -> {k, strip_xml_meta(v)} end)
  end

  defp strip_xml_meta(list) when is_list(list), do: Enum.map(list, &strip_xml_meta/1)
  defp strip_xml_meta(other), do: other

  # Llaves que son metadata de reconstrucción, no datos: el orden interno, las
  # declaraciones de namespace (cualquier prefijo) y el schemaLocation (con el
  # prefijo que sea). Se comparan como string para cubrir llaves átomo y string
  # por igual.
  defp xml_meta_key?(k) do
    s = to_string(k)

    cond do
      s == "__order__" -> true
      s == "xmlns" -> true
      String.starts_with?(s, "xmlns:") -> true
      s == "schemaLocation" -> true
      String.ends_with?(s, ":schemaLocation") -> true
      true -> false
    end
  end

  # Proyección interna: SIEMPRE preserva la convención atom-vs-string para
  # que `to_xml` pueda reconstruir el XML. `to_map` público aplica el
  # transform de llaves cuando `ns: false`.
  defp to_internal_map(%__MODULE__{comprobante: nil}, _opts), do: %{}

  defp to_internal_map(%__MODULE__{comprobante: %Comprobante{} = comp}, opts) do
    Comprobante.to_map(comp, opts)
  end

  defp transform_keys(map, fun) when is_map(map) do
    Map.new(map, fn {k, v} -> {fun.(k), transform_keys(v, fun)} end)
  end

  defp transform_keys(list, fun) when is_list(list),
    do: Enum.map(list, &transform_keys(&1, fun))

  defp transform_keys(other, _fun), do: other

  # Compone case-fn (string→string) seguido de keys-fn (string|atom → string|atom).
  defp key_transformer(keys_mode, case_mode) do
    case_fn = case_fn(case_mode)
    base_fn = base_key_fn(keys_mode)
    fn k -> k |> case_fn.() |> base_fn.() end
  end

  defp base_key_fn(:string), do: &stringify_key/1
  defp base_key_fn(:atom), do: &atomize_key/1
  defp base_key_fn(:existing), do: &existing_atom_key/1

  defp base_key_fn(other),
    do:
      raise(
        ArgumentError,
        "opción :keys inválida: #{inspect(other)}; usar :string, :atom o :existing"
      )

  defp case_fn(:as_is), do: fn k -> k end
  defp case_fn(:camel), do: &camel_case_key/1

  defp case_fn(other),
    do:
      raise(
        ArgumentError,
        "opción :case inválida: #{inspect(other)}; usar :as_is o :camel"
      )

  defp stringify_key(k) when is_atom(k), do: Atom.to_string(k)
  defp stringify_key(k) when is_binary(k), do: k

  defp atomize_key(k) when is_atom(k), do: k
  defp atomize_key(k) when is_binary(k), do: String.to_atom(k)

  defp existing_atom_key(k) when is_atom(k), do: k

  defp existing_atom_key(k) when is_binary(k) do
    String.to_existing_atom(k)
  rescue
    ArgumentError -> k
  end

  # Pasa la primera letra a minúscula, deja el resto intacto.
  # `NoCertificado` → `noCertificado`, `Rfc` → `rfc`, `UsoCFDI` → `usoCFDI`.
  # Devuelve siempre string; el `base_key_fn` luego convierte a átomo si
  # corresponde.
  defp camel_case_key(k) when is_atom(k), do: k |> Atom.to_string() |> camel_case_key()

  defp camel_case_key(<<first::utf8, rest::binary>>),
    do: String.downcase(<<first::utf8>>) <> rest

  defp camel_case_key(""), do: ""

  @doc """
  Serializa el CFDI a XML respetando el orden de elementos que exige el
  Anexo 20 del SAT (indispensable para que los XSLT de cadena original
  procesen el documento correctamente).

  Opciones:
    * `:pretty` — `true` indenta el XML para lectura humana; `false` (default)
      produce XML compacto en una sola línea.
  """
  @spec to_xml(t()) :: String.t()
  def to_xml(%__MODULE__{} = cfdi), do: to_xml(cfdi, [])

  @spec to_xml(t(), keyword()) :: String.t()
  def to_xml(%__MODULE__{} = cfdi, opts) when is_list(opts) do
    format = if Keyword.get(opts, :pretty, false), do: :indent, else: :none

    cfdi
    |> to_internal_map(opts)
    |> map_to_xml(format)
  end

  @doc """
  Serializa el CFDI a JSON.

  Opciones:
    * `:ns` — `true` (default) incluye prefijos `cfdi:`; `false` los omite.
    * `:pretty` — `true` indenta el JSON; `false` (default) compacto.
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = cfdi), do: to_json(cfdi, [])

  @spec to_json(t(), keyword()) :: String.t()
  def to_json(%__MODULE__{} = cfdi, opts) when is_list(opts) do
    json_opts = if Keyword.get(opts, :pretty, false), do: [pretty: true], else: []
    Jason.encode!(to_map(cfdi, opts), json_opts)
  end

  # Orden canónico de hijos por tag padre (CFDI 4.0 Anexo 20).
  @child_order %{
    "cfdi:Comprobante" => [
      "cfdi:InformacionGlobal",
      "cfdi:CfdiRelacionados",
      "cfdi:Emisor",
      "cfdi:Receptor",
      "cfdi:Conceptos",
      "cfdi:Impuestos",
      "cfdi:Complemento",
      "cfdi:Addenda"
    ],
    "cfdi:Concepto" => [
      "cfdi:Impuestos",
      "cfdi:ACuentaTerceros",
      "cfdi:InformacionAduanera",
      "cfdi:CuentaPredial",
      "cfdi:ComplementoConcepto",
      "cfdi:Parte"
    ],
    "cfdi:Impuestos" => [
      "cfdi:Retenciones",
      "cfdi:Traslados"
    ],
    "cfdi:Parte" => [
      "cfdi:InformacionAduanera"
    ]
  }

  @spec map_to_xml(map(), atom()) :: String.t()
  defp map_to_xml(m, _format) when m == %{}, do: ""

  defp map_to_xml(map, format) when is_map(map) do
    [{tag, body}] = Map.to_list(map)

    tag
    |> to_element(body)
    |> XmlBuilder.document()
    |> XmlBuilder.generate(format: format)
  end

  # Construye una tupla de `XmlBuilder.element/3` separando atributos (llaves
  # átomo) de elementos hijos (llaves string) y ordenando según el tag padre.
  defp to_element(tag, body) when is_binary(tag) and is_map(body) do
    # `:__order__` es metadata de orden, no un atributo: se saca antes de
    # separar atributos de hijos. Ver `sort_children/3`.
    {orden_explicito, body} = Map.pop(body, :__order__)

    {attr_pairs, child_pairs} = Enum.split_with(body, fn {k, _} -> is_atom(k) end)

    attrs = Map.new(attr_pairs, fn {k, v} -> {Atom.to_string(k), to_string(v)} end)

    kids =
      child_pairs
      |> sort_children(tag, orden_explicito)
      |> Enum.flat_map(&render_child/1)

    XmlBuilder.element(tag, attrs, kids)
  end

  # Hoja de texto (elemento sin hijos ni atributos, solo valor escalar).
  defp to_element(tag, value) when is_binary(tag), do: XmlBuilder.element(tag, to_string(value))

  defp render_child({tag, value}) when is_map(value), do: [to_element(tag, value)]

  defp render_child({tag, list}) when is_list(list) do
    Enum.map(list, fn item -> to_element(tag, item) end)
  end

  defp render_child({tag, value}), do: [to_element(tag, value)]

  # El SAT declara los hijos con `<xs:sequence>`: el orden es parte del
  # contrato y un documento desordenado se rechaza en validación de esquema.
  # Un mapa no lo puede expresar (itera por término, o sea alfabético), así que
  # el orden viene de tres fuentes, de más específica a más general:
  #
  #   1. `:__order__` — orden explícito del documento de origen, que pone
  #      `Cfdi.Decoder`. Es el único que sabe de esquemas ajenos (addendas).
  #   2. `@child_order` — los elementos propios de `cfdi:`.
  #   3. `Cfdi.Complementos.ChildOrder` — catálogo generado desde los XSLT
  #      oficiales del SAT, para complementos armados a mano.
  #
  # Sin ninguna de las tres, se respeta el orden del mapa.
  defp sort_children(pairs, parent_tag, orden_explicito) do
    order =
      orden_explicito || Map.get(@child_order, parent_tag) ||
        Cfdi.Complementos.ChildOrder.for_tag(parent_tag)

    case order do
      nil ->
        pairs

      order ->
        Enum.sort_by(pairs, fn {k, _} ->
          Enum.find_index(order, &(&1 == k)) || length(order)
        end)
    end
  end
end
