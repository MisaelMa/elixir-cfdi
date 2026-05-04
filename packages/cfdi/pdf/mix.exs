defmodule Cfdi.Pdf.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_pdf,
      version: "0.0.10",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Tipos y opciones para generación de PDF de CFDI"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
