defmodule Cfdi.Complementos.Complemento do
  @moduledoc """
  Estructura base, comportamiento y DSL común de los complementos SAT.

  Cada complemento concreto se declara con `use Cfdi.Complementos.Complemento`
  pasando sus tres constantes:

      defmodule Cfdi.Complementos.Iedu do
        use Cfdi.Complementos.Complemento,
          key: "iedu:instEducativas",
          xmlns: "http://www.sat.gob.mx/iedu",
          xsd: "http://www.sat.gob.mx/sitio_internet/cfd/iedu/iedu.xsd"
      end

  El macro genera:

    * `defstruct [:data]` — la carga útil es un mapa opaco
    * `new/1` — envuelve el mapa
    * `get_complement/1` — metadatos + carga útil para ensamblar
      `cfdi:Complemento` y `xsi:schemaLocation`
    * `key/0`, `xmlns/0`, `xsd/0`, `xmlns_key/0`, `local_name/0` — accessors
    * `__complemento__/0` — marca de introspección que usa
      `Cfdi.Complementos.Registry` para el descubrimiento

  ## Identidad de un complemento

  El identificador **autoritativo** de un complemento es la URI de su
  namespace (`xmlns/0`), NO el prefijo. El prefijo que aparece en `key/0`
  (`iedu`, `pago20`) es la convención del SAT y la que emitimos al
  serializar, pero un XML de terceros puede declarar el mismo namespace
  con cualquier prefijo:

      <x:instEducativas xmlns:x="http://www.sat.gob.mx/iedu"/>

  sigue siendo el complemento de instituciones educativas. Por eso
  `Registry.by_xmlns/1` es la vía de resolución preferida al decodificar
  XML, y `Registry.by_key/1` sólo sirve cuando ya se conoce la key
  canónica.
  """

  defstruct [:key, :xmlns, :xsd, :data]

  @type t :: %__MODULE__{
          key: String.t() | nil,
          xmlns: String.t() | nil,
          xsd: String.t() | nil,
          data: term() | nil
        }

  @typedoc """
  Mapa estándar para ensamblar `cfdi:Complemento` y `xsi:schemaLocation`.
  """
  @type complement_result :: %{
          complement: term(),
          key: String.t(),
          schema_location: String.t(),
          xmlns: String.t(),
          xmlns_key: String.t()
        }

  @callback get_complement(term()) :: complement_result()

  @doc """
  Metadatos de un complemento **genérico**, no registrado.

  `Cfdi.Decoder` cae acá cuando encuentra en un XML un complemento cuyo
  namespace no resuelve a ningún módulo conocido: en vez de descartarlo
  —perder datos fiscales en silencio— lo envuelve en este struct, que
  preserva su key, su namespace y su carga útil. Así el complemento
  sobrevive el ida y vuelta aunque la librería no lo conozca.
  """
  @spec get_complement(t()) :: complement_result()
  def get_complement(%__MODULE__{key: key, xmlns: xmlns, xsd: xsd, data: data}) do
    %{
      complement: data,
      key: key,
      schema_location: schema_location(xmlns, xsd),
      xmlns: xmlns,
      xmlns_key: key |> to_string() |> String.split(":", parts: 2) |> hd()
    }
  end

  defp schema_location(nil, _xsd), do: ""
  defp schema_location(xmlns, nil), do: xmlns
  defp schema_location(xmlns, xsd), do: xmlns <> " " <> xsd

  @doc false
  defmacro __using__(opts) do
    key = Keyword.fetch!(opts, :key)
    xmlns = Keyword.fetch!(opts, :xmlns)
    xsd = Keyword.fetch!(opts, :xsd)

    # El split va acá, en tiempo de expansión: una `key` sin prefijo revienta
    # al compilar el complemento y no cuando alguien lo serialice en producción.
    [xmlns_key, local_name] =
      case String.split(key, ":", parts: 2) do
        [prefix, name] when prefix != "" and name != "" ->
          [prefix, name]

        _ ->
          raise ArgumentError,
                "key de complemento inválida: #{inspect(key)}; " <>
                  "se espera \"prefijo:NombreLocal\" (ej. \"pago20:Pagos\")"
      end

    quote bind_quoted: [
            key: key,
            xmlns: xmlns,
            xsd: xsd,
            xmlns_key: xmlns_key,
            local_name: local_name
          ] do
      @behaviour Cfdi.Complementos.Complemento

      @key key
      @xmlns xmlns
      @xsd xsd
      @xmlns_key xmlns_key
      @local_name local_name

      defstruct [:data]

      @type data :: map()
      @type t :: %__MODULE__{data: data()}

      @doc """
      Crea un builder del complemento a partir de un mapa (o struct, como mapa).
      """
      @spec new(map()) :: t()
      def new(data) when is_map(data), do: %__MODULE__{data: data}

      @doc "Key canónica del complemento con su prefijo. Ej: `\"pago20:Pagos\"`."
      @spec key() :: String.t()
      def key(), do: @key

      @doc "URI del namespace. Identificador autoritativo del complemento."
      @spec xmlns() :: String.t()
      def xmlns(), do: @xmlns

      @doc "URL del XSD publicado por el SAT."
      @spec xsd() :: String.t()
      def xsd(), do: @xsd

      @doc "Prefijo del namespace. Ej: `\"pago20\"`."
      @spec xmlns_key() :: String.t()
      def xmlns_key(), do: @xmlns_key

      @doc "Nombre local del elemento, sin prefijo. Ej: `\"Pagos\"`."
      @spec local_name() :: String.t()
      def local_name(), do: @local_name

      @doc false
      def __complemento__(), do: %{key: @key, xmlns: @xmlns, xsd: @xsd}

      @impl Cfdi.Complementos.Complemento
      def get_complement(%__MODULE__{data: data}) do
        %{
          complement: data,
          key: @key,
          schema_location: @xmlns <> " " <> @xsd,
          xmlns: @xmlns,
          xmlns_key: @xmlns_key
        }
      end

      defoverridable new: 1, get_complement: 1
    end
  end
end
