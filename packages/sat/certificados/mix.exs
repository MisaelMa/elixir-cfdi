defmodule Sat.Certificados.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_certificados,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "CSD — .cer / .key para CFDI",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger, :public_key, :crypto, :inets, :ssl]]
  end

  defp deps do
    [
      {:clir_openssl, path: "../../clir/openssl"}
    ]
  end
end
