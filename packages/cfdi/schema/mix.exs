defmodule Cfdi.Schema.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_schema,
      version: "0.0.13",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Carga y utilidades para esquemas XSD/JSON del SAT"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:saxy, "~> 1.5"}]
  end
end
