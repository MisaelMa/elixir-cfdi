defmodule CFDI do
  @moduledoc """
  Orquestador principal del CFDI 4.0.

  Recibe un `%Cfdi.Comprobante{}` previamente armado con sus elementos
  (`Emisor`, `Receptor`, `Conceptos`, …), lo certifica, sella y serializa
  a XML, mapa o JSON.
  """

  alias Cfdi.Comprobante
  alias Sat.Certificados.{Certificate, Credential}

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
  Firma la cadena original y escribe el atributo `Sello`.
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
  Proyecta el CFDI a un mapa.

  Opciones:
    * `:ns` — `true` (default) incluye el prefijo `cfdi:` en los nombres de
      elementos; `false` los omite (ej. `%{"Comprobante" => ...}`).

  Convenciones de llaves:
    * strings (`"cfdi:Emisor"`) son elementos XML.
    * átomos (`:Rfc`, `:Nombre`) son atributos XML.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = cfdi), do: to_map(cfdi, [])

  @spec to_map(t(), keyword()) :: map()
  def to_map(%__MODULE__{comprobante: nil}, _opts), do: %{}

  def to_map(%__MODULE__{comprobante: %Comprobante{} = comp}, opts) do
    Comprobante.to_map(comp, opts)
  end

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
    |> to_map(opts)
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
