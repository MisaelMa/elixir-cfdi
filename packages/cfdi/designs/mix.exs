defmodule Cfdi.Designs.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_designs,
      version: "1.0.0",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "PDF layouts for CFDI (A117, etc.)"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:cfdi_xml2json, path: "../xml2json"},
      {:cfdi_utils, path: "../utils"},
      {:cfdi_types, path: "../types"},
      {:cfdi_complementos, path: "../complementos"}
    ]
  end
end
