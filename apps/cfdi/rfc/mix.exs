defmodule Cfdi.Rfc.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_rfc,
      version: "0.0.10",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Validación de RFC del SAT (persona física y moral)"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
