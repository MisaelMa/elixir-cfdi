defmodule Cfdi.Validador.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_validador,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Validación basada en reglas para CFDI"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:saxy, "~> 1.5"}]
  end
end
