defmodule Sat.Xsd.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_xsd,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Validación CFDI basada en esquemas JSON",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_json_schema, "~> 0.10"},
      {:jason, "~> 1.0"}
    ]
  end
end
