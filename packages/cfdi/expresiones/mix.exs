defmodule Cfdi.Expresiones.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_expresiones,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Expresiones impresas para CFDI (cadena para QR, etc.)"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
