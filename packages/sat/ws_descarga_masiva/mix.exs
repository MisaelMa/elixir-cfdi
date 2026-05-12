defmodule Sat.WsDescargaMasiva.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_ws_descarga_masiva,
      version: "0.1.0",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Cliente del Web Service oficial de Descarga Masiva del SAT (cfdidescargamasiva.clouda.sat.gob.mx). Solicita, verifica y descarga paquetes ZIP de CFDIs firmando con FIEL.",
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger, :public_key, :crypto, :ssl, :xmerl]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:req, "~> 0.5"},
      {:saxy, "~> 1.5"},
      {:sat_certificados, path: "../certificados"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/MisaelMa/elixir-cfdi"},
      maintainers: ["Misael Madrigal"]
    ]
  end
end
