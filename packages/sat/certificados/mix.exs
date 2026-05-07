defmodule Sat.Certificados.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_certificados,
      version: "4.1.0",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "CSD — .cer / .key para CFDI",
      package: package(),
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger, :public_key, :crypto, :inets, :ssl]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:clir_openssl, path: "../../clir/openssl"}
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
