defmodule Cfdi.Transform.MixProject do
  use Mix.Project

  def project do
    [
      app: :cfdi_transform,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Parser XSLT y motor de cadena original para CFDI",
      releaser: [publish: true]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:saxy, "~> 1.5"},
      {:saxon_he, path: "../../clir/saxon_he", only: [:dev, :test]}
    ]
  end
end
