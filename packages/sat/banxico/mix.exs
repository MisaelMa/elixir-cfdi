defmodule Sat.Banxico.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_banxico,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Cliente para la API SIE de Banxico (tipos de cambio)"
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
