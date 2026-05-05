defmodule Cfdi.Types.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_types,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Interfaces y tipos para CFDI 4.0"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
