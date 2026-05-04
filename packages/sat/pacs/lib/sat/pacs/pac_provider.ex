defmodule Sat.Pacs.PacProvider do
  @moduledoc false

  alias Sat.Pacs.Types.{
    CancelacionPacResult,
    ConsultaEstatusResult,
    TimbradoRequest,
    TimbradoResult
  }

  @callback timbrar(TimbradoRequest.t()) :: {:ok, TimbradoResult.t()} | {:error, term()}

  @callback cancelar(String.t(), String.t(), String.t(), String.t()) ::
              {:ok, CancelacionPacResult.t()} | {:error, term()}

  @callback consultar_estatus(String.t()) ::
              {:ok, ConsultaEstatusResult.t()} | {:error, term()}
end
