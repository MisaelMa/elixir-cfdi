defmodule SaxonHe.MixProject do
  use Mix.Project

  def project do
    [
      app: :saxon_he,
      version: "12.5.2",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Saxon-HE CLI wrapper for XSLT and XQuery"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
