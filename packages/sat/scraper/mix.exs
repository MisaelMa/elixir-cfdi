defmodule Sat.Scraper.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_scraper,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "SAT portal HTTP scraper (CIEC / FIEL)"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:req, "~> 0.5"}]
  end
end
