defmodule CFDI do
  @moduledoc """
  Orquestador principal del CFDI 4.0.

  Recibe un `%Cfdi.Comprobante{}` previamente armado con sus elementos
  (`Emisor`, `Receptor`, `Conceptos`, …), lo certifica, sella y serializa
  a XML, mapa o JSON.
  """

  alias Cfdi.Comprobante
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
  Asocia certificado y número de certificado al comprobante.
  """
  @spec certificar(t(), Credential.t()) :: {:ok, t()} | {:error, atom()}
  def certificar(%__MODULE__{comprobante: comp} = c, %Credential{} = cred) do
    updated =
      struct(comp, %{
        Certificado: Certificate.to_base64(cred.certificate),
        NoCertificado: Credential.no_certificado(cred)
      })

    {:ok, %{c | comprobante: updated, config: Map.put(c.config, :credential, cred)}}
  end

  def certificar(%__MODULE__{}, _), do: {:error, :credential_must_be_credential_struct}


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
  Proyecta el CFDI a un mapa.

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
    base = to_internal_map(cfdi, opts)

    if Keyword.get(opts, :ns, true) do
      base
    else
      keys_mode = Keyword.get(opts, :keys, :string)
      case_mode = Keyword.get(opts, :case, :as_is)
      transform_keys(base, key_transformer(keys_mode, case_mode))
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
      raise(ArgumentError,
        "opción :keys inválida: #{inspect(other)}; usar :string, :atom o :existing"
      )

  defp case_fn(:as_is), do: fn k -> k end
  defp case_fn(:camel), do: &camel_case_key/1

  defp case_fn(other),
    do:
      raise(ArgumentError,
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
    {attr_pairs, child_pairs} = Enum.split_with(body, fn {k, _} -> is_atom(k) end)

    attrs = Map.new(attr_pairs, fn {k, v} -> {Atom.to_string(k), to_string(v)} end)

    kids =
      child_pairs
      |> sort_children(tag)
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

  defp sort_children(pairs, parent_tag) do
    case Map.get(@child_order, parent_tag) do
      nil ->
        pairs

      order ->
        Enum.sort_by(pairs, fn {k, _} ->
          Enum.find_index(order, &(&1 == k)) || length(order)
        end)
    end
  end

end
