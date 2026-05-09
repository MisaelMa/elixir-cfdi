defmodule Sat.Csf do
  @moduledoc """
  Extrae datos estructurados de una **Constancia de Situación Fiscal (CSF)**
  emitida por el SAT a partir de su PDF.

  ## Uso

      {:ok, %Sat.Csf.Document{} = csf} = Sat.Csf.from_file("priv/csf.pdf")

      csf.identificacion.rfc
      #=> "XAXX010101000"

      csf.regimenes
      #=> [%Sat.Csf.Regimen{regimen: "...", codigo: "626", ...}, ...]

  Bajo el capó usa `Pdf.Reader.read/2` con `dictionary: :es` para reconstruir
  el texto correctamente. El parser de la respuesta (`Sat.Csf.Parser`) usa
  posiciones X de tokens para separar columnas en las tablas de obligaciones.

  ## Errores

  - `{:error, :not_a_csf}` — el PDF no contiene los marcadores de sección
    de un CSF (no se detectó "Datos de Identificación del Contribuyente").
  - cualquier error reportado por `Pdf.Reader.open/2` o `Pdf.Reader.read/2`.
  """

  alias Sat.Csf.{Document, Parser}

  @type from_result :: {:ok, Document.t()} | {:error, term()}

  @default_read_opts [dictionary: :es]

  @doc """
  Lee y parsea un CSF desde una ruta de archivo.

  Las opciones se pasan a `Pdf.Reader.read/2`. Por defecto se incluye
  `dictionary: :es` para que el extractor separe palabras pegadas (puedes
  sobrescribirlo pasando `dictionary: nil` o tu propia `MapSet`).
  """
  @spec from_file(Path.t(), keyword()) :: from_result()
  def from_file(path, opts \\ []) when is_binary(path) do
    open_and_parse(path, opts)
  end

  @doc """
  Lee y parsea un CSF desde un binario `.pdf` ya cargado en memoria.
  """
  @spec from_binary(binary(), keyword()) :: from_result()
  def from_binary(<<"%PDF-", _::binary>> = bin, opts \\ []) do
    open_and_parse(bin, opts)
  end

  @doc """
  Parsea un `%Pdf.Reader.Result{}` ya extraído. Útil si ya estás trabajando
  con el reader y quieres evitar reabrir el PDF.
  """
  @spec from_result(Pdf.Reader.Result.t()) :: from_result()
  def from_result(%Pdf.Reader.Result{} = result) do
    Parser.parse(result)
  end

  defp open_and_parse(path_or_bin, opts) do
    read_opts = Keyword.merge(@default_read_opts, opts)

    with {:ok, doc} <- Pdf.Reader.open(path_or_bin),
         {:ok, result, _doc} <- Pdf.Reader.read(doc, read_opts) do
      Parser.parse(result)
    end
  end

  @doc false
  def version, do: Application.spec(:sat_csf, :vsn)
end
