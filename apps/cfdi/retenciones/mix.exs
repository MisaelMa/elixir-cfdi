defmodule Cfdi.Retenciones.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_retenciones,
      version: "0.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Generación de XML de Retenciones e información de pagos"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
