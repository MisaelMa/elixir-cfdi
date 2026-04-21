defmodule Cfdi.Csf.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_csf,
      version: "4.0.16",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Constancia de Situación Fiscal (CSF) desde texto de PDF"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
