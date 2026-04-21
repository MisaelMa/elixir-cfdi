defmodule Cfdi.Utils.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_utils,
      version: "4.0.17",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Utilidades para CFDI (número a letras, montos, etc.)"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
