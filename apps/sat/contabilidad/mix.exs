defmodule Sat.Contabilidad.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_contabilidad,
      version: "0.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Generación de XML de Contabilidad Electrónica (Anexo 24)"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
