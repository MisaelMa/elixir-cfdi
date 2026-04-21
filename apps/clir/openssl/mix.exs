defmodule Clir.Openssl.MixProject do
  use Mix.Project

  def project do
    [
      app: :clir_openssl,
      version: "0.0.17",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Wrapper de OpenSSL para certificados digitales del SAT",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger, :public_key, :crypto]]
  end

  defp deps do
    []
  end
end
