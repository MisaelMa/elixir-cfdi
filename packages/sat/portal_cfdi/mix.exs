defmodule Sat.PortalCfdi.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_portal_cfdi,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Cliente HTTP del portal CFDI del SAT (portalcfdi.facturaelectronica.sat.gob.mx). Login con CIEC o FIEL, consulta y descarga de XML uno-por-uno.",
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger, :public_key, :crypto, :ssl]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:floki, "~> 0.36"},
      {:browser_tls, path: "../../browser/tls"},
      {:sat_certificados, path: "../certificados"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/MisaelMa/elixir-cfdi"},
      maintainers: ["Misael Madrigal"],
      # Lista explicita: solo lo listado se sube al Hex package.
      # Cualquier `.onnx` en `priv/models/` (o donde sea) NO se incluye.
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end
end
