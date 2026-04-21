defmodule Cfdi.Descarga.DescargaMasiva do
  @moduledoc """
  Facade for SAT *Descarga Masiva*: `solicitar/2`, `verificar/2`, `descargar/2`.
  """

  alias Cfdi.Descarga.Soap.{Descargar, Solicitar, Verificar}
  alias Cfdi.Descarga.Types.SolicitudParams
  alias Sat.Auth.Types.SatToken

  @url_solicitar "https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/SolicitaDescargaService.svc"
  @url_verificar "https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/VerificaSolicitudDescargaService.svc"
  @url_descargar "https://cfdidescargamasiva.clouda.sat.gob.mx/DescargaMasivaService.svc"

  @action_solicitar "http://DescargaMasivaTerceros.sat.gob.mx/ISolicitaDescargaService/SolicitaDescarga"
  @action_verificar "http://DescargaMasivaTerceros.sat.gob.mx/IVerificaSolicitudDescargaService/VerificaSolicitudDescarga"
  @action_descargar "http://DescargaMasivaTerceros.sat.gob.mx/IDescargaMasivaTercerosService/Descargar"

  @timeout 60_000

  defstruct [:token, :credential]

  @type t :: %__MODULE__{
          token: SatToken.t(),
          credential: Cfdi.Csd.Credential.t()
        }

  @spec solicitar(t(), SolicitudParams.t()) ::
          {:ok, Cfdi.Descarga.Types.SolicitudResult.t()} | {:error, String.t()}
  def solicitar(%__MODULE__{token: token, credential: cred}, %SolicitudParams{} = params) do
    {cert, sig} = sign_components(cred, "SolicitudDescarga-#{params.rfc_solicitante}")
    body = Solicitar.build_solicitar_request(params, token.value, cert, sig)

    with {:ok, xml} <- post(@url_solicitar, @action_solicitar, body) do
      Solicitar.parse_solicitar_response(xml)
    end
  end

  @spec verificar(t(), String.t()) ::
          {:ok, Cfdi.Descarga.Types.VerificacionResult.t()} | {:error, String.t()}
  def verificar(%__MODULE__{token: token, credential: cred}, id_solicitud) do
    rfc = Cfdi.Csd.Credential.rfc(cred)
    {cert, sig} = sign_components(cred, "VerificaSolicitud-#{id_solicitud}")
    body = Verificar.build_verificar_request(id_solicitud, rfc, token.value, cert, sig)

    with {:ok, xml} <- post(@url_verificar, @action_verificar, body) do
      Verificar.parse_verificar_response(xml)
    end
  end

  @spec descargar(t(), String.t()) :: {:ok, binary()} | {:error, String.t()}
  def descargar(%__MODULE__{token: token, credential: cred}, id_paquete) do
    rfc = Cfdi.Csd.Credential.rfc(cred)
    {cert, sig} = sign_components(cred, "Descarga-#{id_paquete}")
    body = Descargar.build_descargar_request(id_paquete, rfc, token.value, cert, sig)

    with {:ok, xml} <- post(@url_descargar, @action_descargar, body) do
      Descargar.parse_descargar_response(xml)
    end
  end

  defp sign_components(%Cfdi.Csd.Credential{} = cred, content) do
    sig = Cfdi.Csd.Credential.sign(cred, content)
    pem = Cfdi.Csd.Certificate.to_pem(cred.certificate)

    cert =
      pem
      |> String.replace("-----BEGIN CERTIFICATE-----", "")
      |> String.replace("-----END CERTIFICATE-----", "")
      |> String.replace(~r/\s+/, "")

    {cert, sig}
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
        {:error, "SAT HTTP #{status}: #{truncate(resp)}"}

      {:error, reason} ->
        {:error, "network error: #{inspect(reason)}"}
    end
  end

  defp truncate(bin) when is_binary(bin), do: String.slice(bin, 0, 400)
  defp truncate(_), do: ""
end
