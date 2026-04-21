defmodule Sat.Auth.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_auth,
      version: "1.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "FIEL-based SOAP authentication for SAT Descarga Masiva"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:cfdi_csd, path: "../../cfdi/csd"},
      {:req, "~> 0.5"}
    ]
  end
end
