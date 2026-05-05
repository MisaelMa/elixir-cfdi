defmodule CFDI.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Construcción, sellado y timbrado de CFDI",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:sat_certificados, path: "../../sat/certificados"},
      {:cfdi_transform, path: "../transform"},
      {:cfdi_complementos, path: "../complementos"},
      {:sat_catalogos, path: "../../sat/catalogos"},
      {:sat_xsd, path: "../../sat/xsd"},
      {:saxon_he, path: "../../clir/saxon_he"},
      {:xml_builder, "~> 2.1"},
      {:saxy, "~> 1.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
