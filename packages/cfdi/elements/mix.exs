defmodule Cfdi.Elements.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_elements,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elementos estructurales y constantes de tags CFDI"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
