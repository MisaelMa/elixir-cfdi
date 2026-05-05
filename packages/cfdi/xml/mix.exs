defmodule Cfdi.Xml.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_xml,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Conversión de CFDI XML a estructura tipo JSON",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:saxy, "~> 1.5"},
      {:xml_builder, "~> 2.1"}
    ]
  end
end
