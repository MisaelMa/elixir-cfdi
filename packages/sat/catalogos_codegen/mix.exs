defmodule Sat.Catalogos.Codegen.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_catalogos_codegen,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Codegen para sat_catalogos — genera módulos desde catCFDI.xsd y catCFDI.xlsx",
      releaser: [publish: false]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:saxy, "~> 1.6"},
      {:sat_recursos, path: "../recursos", only: [:dev, :test]},
      {:plug, "~> 1.0", only: :test}
    ]
  end
end
