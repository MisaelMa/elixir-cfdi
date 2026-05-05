defmodule Cfdi.Descarga.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_descarga,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Descarga masiva CFDI (SOAP SAT)"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:sat_auth, path: "../../sat/auth"},
      {:req, "~> 0.5"}
    ]
  end
end
