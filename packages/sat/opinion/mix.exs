defmodule Sat.Opinion.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_opinion,
      version: "4.0.1",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Opinión de cumplimiento (32-D) SAT",
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:req, "~> 0.5"}]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/MisaelMa/elixir-cfdi"},
      maintainers: ["Misael Madrigal"]
    ]
  end
end
