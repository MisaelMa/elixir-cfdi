defmodule Sat.Pacs do
  @moduledoc """
  PAC provider abstraction (`Sat.Pacs.PacProvider`, `Sat.Pacs.Providers.Finkok`).
  """

  @doc false
  def version, do: Application.spec(:sat_pacs, :vsn)
end
