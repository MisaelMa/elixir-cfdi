defmodule Sat.Auth do
  @moduledoc """
  FIEL-based WS-Security authentication for SAT *Descarga Masiva* and related SOAP services.

  Use `Sat.Auth.SatAuth.authenticate/1` with a `Sat.Certificados.Credential` (or compatible struct).
  """

  @doc false
  def version, do: Application.spec(:sat_auth, :vsn)
end
