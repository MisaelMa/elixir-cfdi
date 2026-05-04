defmodule Cfdi.Catalogos.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_catalogos,
      version: "4.0.16",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Catálogos oficiales del SAT para CFDI 4.0",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
