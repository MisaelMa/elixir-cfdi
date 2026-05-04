defmodule Renapo.Curp do
  @moduledoc """
  CURP validation and RENAPO HTTP helpers (`Renapo.Curp.Curp`, `Renapo.Curp.Service.GobService`).
  """

  @doc false
  def version, do: Application.spec(:renapo_curp, :vsn)
end
