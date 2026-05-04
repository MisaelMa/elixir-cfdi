defmodule Sat.Scraper.SatPortal do
  @moduledoc false

  alias Sat.Scraper.Types.{
    CfdiConsultaResult,
    ConsultaCfdiParams,
    CredencialPortal,
    SesionSAT
  }

  @spec login(CredencialPortal.t()) :: {:ok, SesionSAT.t()} | {:error, String.t()}
  def login(%CredencialPortal{} = _cred) do
    {:error,
     "SatPortal.login/1 is not implemented (portal flow changes frequently); base URL typically https://portalcfdi.facturaelectronica.sat.gob.mx"}
  end

  @spec consultar_cfdis(SesionSAT.t(), ConsultaCfdiParams.t()) ::
          {:ok, CfdiConsultaResult.t()} | {:error, String.t()}
  def consultar_cfdis(%SesionSAT{} = _sesion, %ConsultaCfdiParams{} = _params) do
    {:error, "SatPortal.consultar_cfdis/2 is not implemented"}
  end

  @spec logout(SesionSAT.t()) :: :ok | {:error, String.t()}
  def logout(%SesionSAT{} = _sesion), do: :ok
end
