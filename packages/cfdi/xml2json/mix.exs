defmodule Cfdi.Xml2Json.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_xml2json,
      version: "4.0.14",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Conversión de CFDI XML a estructura tipo JSON"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:saxy, "~> 1.5"}]
  end
end
