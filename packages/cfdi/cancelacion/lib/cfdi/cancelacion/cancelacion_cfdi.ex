defmodule Cfdi.Cancelacion.CancelacionCfdi do
  @moduledoc """
  Facade: `cancelar/2`, `aceptar_rechazar/2`, `consultar_pendientes/1`.
  """

  alias Cfdi.Cancelacion.Soap.{AceptacionRechazo, Cancelar}
  alias Cfdi.Cancelacion.Types.{AceptacionRechazoParams, CancelacionParams}
  alias Sat.Auth.Types.SatToken

  @url_cancelar "https://cancelacfd.sat.gob.mx/CancelaCFDService.svc"
  @url_aceptacion "https://cancelacfd.sat.gob.mx/AceptacionRechazo/AceptacionRechazoService.svc"

  @action_cancelar "http://cancelacfd.sat.gob.mx/ICancelaCFDService/CancelaCFD"
  @action_aceptacion "http://cancelacfd.sat.gob.mx/IAceptacionRechazoService/ProcesarRespuesta"
  @action_pendientes "http://cancelacfd.sat.gob.mx/IAceptacionRechazoService/ConsultaPendientes"

  @timeout 60_000

  defstruct [:token, :credential]

  @type t :: %__MODULE__{
          token: SatToken.t(),
          credential: Sat.Certificados.Credential.t()
        }

  @spec cancelar(t(), CancelacionParams.t()) ::
          {:ok, Cfdi.Cancelacion.Types.CancelacionResult.t()} | {:error, String.t()}
  def cancelar(%__MODULE__{token: token, credential: cred}, %CancelacionParams{} = params) do
    rfc_emisor = params.rfc_emisor || Sat.Certificados.Credential.rfc(cred)
    fecha = fecha_sat_iso()
    {cert, sig, serial} = sign_components(cred, "CancelaCFD-#{params.uuid}")

    cancel_xml =
      Cancelar.build_cancelacion_xml(params, rfc_emisor, fecha, cert, sig, serial)

    body = Cancelar.build_cancelar_request(cancel_xml, token.value, cert)

    with {:ok, xml} <- post(@url_cancelar, @action_cancelar, body) do
      Cancelar.parse_cancelar_response(xml)
    end
  end

  @spec aceptar_rechazar(t(), AceptacionRechazoParams.t()) ::
          {:ok, Cfdi.Cancelacion.Types.AceptacionRechazoResult.t()} | {:error, String.t()}
  def aceptar_rechazar(%__MODULE__{token: token, credential: cred}, %AceptacionRechazoParams{} = params) do
    fecha = fecha_sat_iso()
    {cert, sig, _} = sign_components(cred, "AceptacionRechazo-#{params.uuid}")

    body =
      AceptacionRechazo.build_aceptacion_rechazo_request(params, token.value, cert, sig, fecha)

    with {:ok, xml} <- post(@url_aceptacion, @action_aceptacion, body) do
      AceptacionRechazo.parse_aceptacion_rechazo_response(xml)
    end
  end

  @spec consultar_pendientes(t()) ::
          {:ok, [Cfdi.Cancelacion.Types.PendientesResult.t()]} | {:error, String.t()}
  def consultar_pendientes(%__MODULE__{token: token, credential: cred}) do
    rfc = Sat.Certificados.Credential.rfc(cred)
    {cert, _, _} = sign_components(cred, "ConsultaPendientes-#{rfc}")

    body = AceptacionRechazo.build_consulta_pendientes_request(rfc, token.value, cert)

    with {:ok, xml} <- post(@url_aceptacion, @action_pendientes, body) do
      AceptacionRechazo.parse_consulta_pendientes_response(xml)
    end
  end

  defp fecha_sat_iso do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%Y-%m-%dT%H:%M:%S")
  end

  defp sign_components(%Sat.Certificados.Credential{} = cred, content) do
    sig = Sat.Certificados.Credential.sign(cred, content)
    pem = Sat.Certificados.Certificate.to_pem(cred.certificate)

    cert =
      pem
      |> String.replace("-----BEGIN CERTIFICATE-----", "")
      |> String.replace("-----END CERTIFICATE-----", "")
      |> String.replace(~r/\s+/, "")

    serial = Sat.Certificados.Certificate.serial_number(cred.certificate)
    {cert, sig, serial}
  end

  defp post(url, soap_action, body) do
    case Req.post(url,
           headers: [
             {"content-type", "text/xml; charset=utf-8"},
             {"SOAPAction", ~s("#{soap_action}")}
           ],
           body: body,
           receive_timeout: @timeout
         ) do
      {:ok, %{status: 200, body: resp}} when is_binary(resp) ->
        {:ok, resp}

      {:ok, %{status: status, body: resp}} ->
        {:error, "cancelacion HTTP #{status}: #{truncate(resp)}"}

      {:error, reason} ->
        {:error, "network error: #{inspect(reason)}"}
    end
  end

  defp truncate(bin) when is_binary(bin), do: String.slice(bin, 0, 400)
  defp truncate(_), do: ""
end
