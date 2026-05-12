defmodule Browser.Tls.MixProject do
  use Mix.Project

  def project do
    [
      app: :browser_tls,
      version: "0.1.0",
      build_path: "../../../_build",
      deps_path: "../../../deps",
      lockfile: "../../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      description:
        "NIF de OpenSSL con perfiles JA3 configurables (Chrome/Firefox/Safari) para bypass de TLS fingerprinting (Akamai, Cloudflare, SAT).",
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.7", runtime: false},
      {:jason, "~> 1.4"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/MisaelMa/elixir-cfdi"},
      maintainers: ["Misael Madrigal"],
      # Solo se publica codigo fuente. El `.so` se compila en cada install.
      files: ~w(lib c_src Makefile mix.exs README.md LICENSE)
    ]
  end
end
