defmodule Cfdi.Xml.Cfdi do
  @moduledoc """
  Constructor de CFDI 4.0: comprobante, emisor, receptor, conceptos,
  complementos, certificado, sello y serialización a XML/JSON.
  """

  alias Cfdi.Xml.Elements
  alias Cfdi.Xml.JsonEncode
  alias Cfdi.Xml.Types.{Comprobante, Concepto, Emisor, Receptor}
  alias XmlBuilder

  defstruct [
    :comprobante,
    :emisor,
    :receptor,
    conceptos: [],
    complementos: [],
    relacionados: [],
    config: %{}
  ]

  @type t :: %__MODULE__{
          comprobante: Comprobante.t() | nil,
          emisor: Emisor.t() | nil,
          receptor: Receptor.t() | nil,
          conceptos: [Concepto.t()],
          complementos: [term()],
          relacionados: [map()],
          config: map()
        }

  def new(attrs \\ []) when is_list(attrs) do
    comprobante = struct(Comprobante, Map.new(attrs))
    %__MODULE__{comprobante: comprobante}
  end

  def emisor(%__MODULE__{} = c, data) when is_map(data) do
    %{c | emisor: struct(Emisor, data)}
  end

  def receptor(%__MODULE__{} = c, data) when is_map(data) do
    %{c | receptor: struct(Receptor, data)}
  end

  def add_concepto(%__MODULE__{} = c, %Concepto{} = concepto) do
    %{c | conceptos: c.conceptos ++ [concepto]}
  end

  def add_concepto(%__MODULE__{} = c, data) when is_map(data) do
    add_concepto(c, struct(Concepto, data))
  end

  def add_complemento(%__MODULE__{} = c, complemento) do
    %{c | complementos: c.complementos ++ [complemento]}
  end

  def add_relacionado(%__MODULE__{} = c, data) when is_map(data) do
    %{c | relacionados: c.relacionados ++ [data]}
  end

  @doc """
  Asocia certificado y número de certificado al comprobante.

  `credential` puede ser un mapa con claves `:certificado`, `:no_certificado` o
  delegarse en `Cfdi.Csd` cuando exista implementación.
  """
  def certificar(%__MODULE__{comprobante: comp} = c, credential) when is_map(credential) do
    cert = Map.get(credential, :certificado) || Map.get(credential, "certificado")
    no = Map.get(credential, :no_certificado) || Map.get(credential, "no_certificado")

    if cert && no do
      updated =
        struct(comp, %{
          Certificado: to_string(cert),
          NoCertificado: to_string(no)
        })

      {:ok, %{c | comprobante: updated, config: Map.put(c.config, :credential, credential)}}
    else
      {:error, :incomplete_credential}
    end
  end

  def certificar(%__MODULE__{} = c, other) do
    _ = c
    _ = other
    {:error, :credential_must_be_map}
  end

  @doc """
  Firma la cadena original y escribe el atributo `Sello`.

  Requiere `Cfdi.Csd.sign_cadena/2` y cadena en `config[:cadena]` o generación externa.
  """
  def sellar(%__MODULE__{comprobante: comp, config: cfg} = c) do
    cadena = Map.get(cfg, :cadena) || Map.get(cfg, "cadena")
    credential = Map.get(cfg, :credential)

    cond do
      is_nil(cadena) ->
        {:error, :missing_cadena}

      true ->
        case Cfdi.Csd.sign_cadena(cadena, credential) do
          {:ok, sello} ->
            {:ok, %{c | comprobante: struct(comp, %{Sello: sello})}}

          {:error, _} = e ->
            e
        end
    end
  end

  @doc """
  Serializa el CFDI a XML (sin timbre fiscal salvo que ya venga en complementos).
  """
  def to_xml(%__MODULE__{} = cfdi) do
    %__MODULE__{comprobante: comp} = cfdi

    inner =
      [
        Elements.Emisor.to_element(cfdi.emisor),
        Elements.Receptor.to_element(cfdi.receptor),
        Elements.Concepto.conceptos_block(cfdi.conceptos),
        Elements.Relacionado.relacionados_block(cfdi.relacionados)
      ]
      |> Enum.reject(&is_nil/1)

    root = Elements.Comprobante.to_element(comp, inner)
    root |> XmlBuilder.document() |> XmlBuilder.generate(format: :none)
  end

  @doc """
  Representación JSON del estado actual (útil para depuración o validadores).
  """
  def get_json(%__MODULE__{} = cfdi) do
    map = %{
      comprobante: comprobante_to_map(cfdi.comprobante),
      emisor: struct_to_map(cfdi.emisor),
      receptor: struct_to_map(cfdi.receptor),
      conceptos: Enum.map(cfdi.conceptos, &struct_to_map/1),
      complementos: cfdi.complementos,
      relacionados: cfdi.relacionados
    }

    JsonEncode.encode!(map)
  end

  defp comprobante_to_map(nil), do: nil
  defp comprobante_to_map(%_{} = s), do: struct_to_map(s)

  defp struct_to_map(nil), do: nil

  defp struct_to_map(%_{} = s) do
    s
    |> Map.from_struct()
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end
end
