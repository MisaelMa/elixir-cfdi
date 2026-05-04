defmodule Clir.Openssl do
  @moduledoc """
  Wrapper de operaciones criptográficas orientadas a certificados X.509 y llaves PKCS#8.

  Usa los módulos OTP `:public_key` y `:crypto`, con `System.cmd("openssl", ...)` como
  respaldo cuando el flujo nativo no alcanza (p. ej. algunos PKCS#8 cifrados del SAT).
  """

  @doc false
  def version, do: Application.spec(:clir_openssl, :vsn)
end
