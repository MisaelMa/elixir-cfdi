defmodule Sat.Cfdi.Descarga.Masiva.Paquete do
  @moduledoc """
  Servicio `DescargaMasivaSolicitudes` del WS de Descarga Masiva.

  Endpoint: `https://cfdidescargamasiva.clouda.sat.gob.mx/DescargaMasivaService.svc`.

  Descarga un paquete por su `id_paquete`. La respuesta contiene el contenido
  del ZIP en base64 dentro del sobre SOAP. Cada paquete puede contener hasta
  10,000 CFDIs.
  """

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.Internal.{Http, Parser, SoapEnvelope}
  alias Sat.Cfdi.Descarga.Masiva.Types.{Paquete, Token}

  @endpoint "https://cfdidescargamasiva.clouda.sat.gob.mx/DescargaMasivaService.svc"
  @soap_action "http://DescargaMasivaTerceros.sat.gob.mx/IDescargaMasivaTercerosService/Descargar"

  @doc """
  Descarga un paquete y devuelve su contenido como bytes ZIP.

  ## Opciones
    * `:credential` (requerido) — FIEL.
    * `:rfc_solicitante` — RFC del solicitante (default: el del certificado).
    * `:endpoint` — override.
    * `:timeout` — HTTP timeout (default 60000 ms, para paquetes grandes).

  ## Retorno

  `{:ok, %Paquete{id, content, size}}` donde `content` son los bytes del ZIP
  (ya decodificado del base64) y `size` su tamaño. Extrae los XML con
  `Sat.Cfdi.Descarga.Masiva.Paquete.Reader.stream_cfdis/1`.

  ### Errores (`{:error, reason}`)

    * `{:descarga_rechazada, cod, mensaje}` — el SAT rechazó la descarga. `cod`:

      | `cod` | Significado |
      |-------|-------------|
      | `"300"` | Usuario No Válido. |
      | `"301"` | XML Mal Formado. |
      | `"302"` | Sello Mal Formado. |
      | `"303"` | El sello no corresponde con RfcSolicitante. |
      | `"304"` | Certificado Revocado o Caduco. |
      | `"305"` | Certificado Inválido. |
      | `"5004"`| No se encontró la información. |
      | `"5007"`| No existe el paquete (vida máx 72 h). |
      | `"5008"`| Máximo de descargas permitidas (cada paquete solo 2 veces). |
      | `"404"` | Error no controlado. |

    * `{:parse_error, :invalid_base64}` — el `<Paquete>` no era base64 válido.
    * `{:parse_error, :missing_paquete, body}` — respuesta sin paquete ni código.
    * cliente: `{:missing_option, :credential}`, `{:http_error, status, body}`,
      `{:network_error, reason}`, `{:soap_fault, code, string}`.

  ## Respuesta cruda del SAT (HTTP 200)

  El estatus viaja en el **header** `<h:respuesta CodEstatus=... Mensaje=.../>` y
  el ZIP en base64 en el **body**, dentro de
  `<RespuestaDescargaMasivaTercerosSalida><Paquete>`. Estructura verificada contra
  el fixture oficial de phpcfdi/sat-ws-descarga-masiva
  (`tests/_files/download/response-with-package-template.xml`):

      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
        <s:Header>
          <h:respuesta CodEstatus="5000" Mensaje="Solicitud Aceptada"
            xmlns:h="http://DescargaMasivaTerceros.sat.gob.mx"/>
        </s:Header>
        <s:Body>
          <RespuestaDescargaMasivaTercerosSalida xmlns="http://DescargaMasivaTerceros.sat.gob.mx">
            <Paquete>UEsDBBQAAAAI...(ZIP en base64)...AAAA==</Paquete>
          </RespuestaDescargaMasivaTercerosSalida>
        </s:Body>
      </s:Envelope>

  Mapeo:

  | XML | Resultado |
  |-----|-----------|
  | `<Paquete>` (base64) | `%Paquete{content: <bytes ZIP>, size: byte_size, id: id_paquete}` |
  | `<h:respuesta CodEstatus="5000">` | éxito → `{:ok, %Paquete{}}` |
  | `<h:respuesta CodEstatus="5008" .../>` sin `<Paquete>` | `{:error, {:descarga_rechazada, "5008", msg}}` |

  > Recuerda: **cada paquete solo se puede descargar 2 veces**; a la 3.ª el SAT
  > responde `CodEstatus="5008"` (sin `<Paquete>`).

  ## Ejemplo

      case Paquete.descargar(token, id_paquete, credential: cred) do
        {:ok, paquete} ->
          {:ok, stream} = Reader.stream_cfdis(paquete)
          Enum.to_list(stream)

        {:error, {:descarga_rechazada, "5008", _}} -> {:error, :ya_descargado_2_veces}
        {:error, {:descarga_rechazada, "5007", _}} -> {:error, :paquete_vencido}
        {:error, reason} -> {:error, reason}
      end
  """
  @spec descargar(Token.t(), String.t(), keyword()) ::
          {:ok, Paquete.t()} | {:error, term()}
  def descargar(%Token{} = token, id_paquete, opts \\ []) when is_binary(id_paquete) do
    opts = Keyword.put_new(opts, :timeout, 60_000)

    with {:ok, %Credential{} = cred} <- fetch_credential(opts),
         {:ok, rfc} <- fetch_rfc(opts, cred),
         envelope = SoapEnvelope.build_descarga(cred, rfc, id_paquete, token.value),
         endpoint = Keyword.get(opts, :endpoint, @endpoint),
         http_opts = Keyword.put(opts, :token, token.value),
         {:ok, %{status: 200, body: body}} <-
           Http.post_soap(endpoint, @soap_action, envelope, http_opts),
         :ok <- Parser.detect_fault(body) do
      Parser.parse_descarga(body, id_paquete)
    else
      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, _} = e ->
        e
    end
  end

  @doc "Endpoint del servicio."
  def endpoint, do: @endpoint

  @doc "SOAPAction."
  def soap_action, do: @soap_action

  defp fetch_credential(opts) do
    case Keyword.fetch(opts, :credential) do
      {:ok, %Credential{} = c} -> {:ok, c}
      {:ok, _} -> {:error, {:invalid_option, :credential, "expected Sat.Certificados.Credential"}}
      :error -> {:error, {:missing_option, :credential}}
    end
  end

  defp fetch_rfc(opts, cred) do
    case Keyword.get(opts, :rfc_solicitante) do
      nil -> {:ok, Credential.rfc(cred)}
      rfc when is_binary(rfc) -> {:ok, rfc}
      _ -> {:error, {:invalid_option, :rfc_solicitante}}
    end
  end
end
