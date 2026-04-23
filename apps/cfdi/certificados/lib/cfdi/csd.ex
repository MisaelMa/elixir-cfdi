defmodule Cfdi.Csd do
  @moduledoc """
  Certificado de Sello Digital (CSD) y FIEL del SAT: certificado X.509 (`.cer`), llave privada (`.key`) y credencial unificada.

  Construye sobre `clir_openssl` (`:public_key`, `:crypto`) para operaciones de certificado y firma.
  """

  @doc false
  def version, do: Application.spec(:cfdi_csd, :vsn)
end
