defmodule Cfdi.Estado.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_estado,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Consulta de estado de CFDI en el webservice del SAT"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:req, "~> 0.5"}
    ]
  end
end
