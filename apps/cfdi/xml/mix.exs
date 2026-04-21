defmodule Cfdi.Xml.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_xml,
      version: "4.0.18",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Construcción, sellado y timbrado de CFDI en XML",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:cfdi_csd, path: "../csd"},
      {:cfdi_transform, path: "../transform"},
      {:cfdi_complementos, path: "../complementos"},
      {:cfdi_catalogos, path: "../catalogos"},
      {:cfdi_xsd, path: "../xsd"},
      {:saxon_he, path: "../../clir/saxon_he"},
      {:xml_builder, "~> 2.1"},
      {:saxy, "~> 1.5"}
    ]
  end
end
