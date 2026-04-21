defmodule Sat.Opinion.OpinionCumplimiento do
  @moduledoc false

  alias Sat.Opinion.Types.{OpinionConfig, OpinionCumplimiento}

  @spec obtener(OpinionConfig.t(), Sat.Opinion.Types.sesion_portal_like()) ::
          {:ok, OpinionCumplimiento.t()} | {:error, String.t()}
  def obtener(%OpinionConfig{} = _config, _sesion) do
    {:error, "OpinionCumplimiento.obtener/2 is not implemented"}
  end

  @spec descargar_pdf(OpinionConfig.t(), Sat.Opinion.Types.sesion_portal_like()) ::
          {:ok, binary()} | {:error, String.t()}
  def descargar_pdf(%OpinionConfig{} = _config, _sesion) do
    {:error, "OpinionCumplimiento.descargar_pdf/2 is not implemented"}
  end
end
