defmodule Sat.Pacs.Providers.Finkok do
  @moduledoc false

  @behaviour Sat.Pacs.PacProvider

  alias Sat.Pacs.Types.{TimbradoRequest, TimbradoResult}

  defstruct [:config]

  @type t :: %__MODULE__{config: Sat.Pacs.Types.PacConfig.t()}

  def new(%Sat.Pacs.Types.PacConfig{} = cfg), do: %__MODULE__{config: cfg}

  @impl true
  def timbrar(%TimbradoRequest{} = _req) do
    {:error, "Finkok timbrado SOAP not implemented"}
  end

  @impl true
  def cancelar(_uuid, _rfc, _motivo, _folio) do
    {:error, "Finkok cancelacion SOAP not implemented"}
  end

  @impl true
  def consultar_estatus(_uuid) do
    {:error, "Finkok consulta estatus SOAP not implemented"}
  end

  @doc """
  Uses `extras[:pac]` or application env to resolve config; placeholder for future wiring.
  """
  @spec timbrar_con(t(), TimbradoRequest.t()) :: {:ok, TimbradoResult.t()} | {:error, term()}
  def timbrar_con(%__MODULE__{}, %TimbradoRequest{} = req), do: __MODULE__.timbrar(req)
end
