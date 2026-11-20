defmodule Cfdi.Transform.ParityTest do
  @moduledoc """
  Paridad de la cadena original contra `xsltproc` + los XSLT oficiales del SAT.

  Cada `test/fixtures/parity/xml/<nombre>.xml` tiene su cadena esperada en
  `test/fixtures/parity/expected/<nombre>.txt`, generada con
  `test/fixtures/parity/generate.sh`. Los tests NO necesitan red ni `xsltproc`.

  Una divergencia real del motor NO se esconde: se marca con
  `@tag :known_divergence` (excluida por defecto; correr con
  `mix test --include known_divergence`).
  """

  use ExUnit.Case, async: true

  alias Cfdi.Transform
  alias Cfdi.Transform.Transform, as: T

  @fixtures Path.expand("fixtures/parity", __DIR__)

  # Complementos en los que el motor difiere de xsltproc (ver el motivo).
  @known_divergences %{}

  for xml <- Path.wildcard(Path.join(@fixtures, "xml/*.xml")) do
    name = Path.basename(xml, ".xml")

    if Map.has_key?(@known_divergences, name) do
      @tag :known_divergence
    end

    test "paridad con xsltproc: #{name}" do
      xml = Path.join(@fixtures, "xml/#{unquote(name)}.xml")

      expected =
        File.read!(Path.join(@fixtures, "expected/#{unquote(name)}.txt")) |> String.trim()

      actual =
        T.new()
        |> T.s(xml)
        |> T.xsl(Transform.bundled_xslt(), strict: true)
        |> T.run!()

      assert actual == expected
    end
  end

  test "hay al menos un fixture por complemento principal" do
    names =
      Path.wildcard(Path.join(@fixtures, "xml/*.xml")) |> Enum.map(&Path.basename(&1, ".xml"))

    for required <- ~w(pago20 nomina12 iedu ventavehiculos10 ventavehiculos11 cartaporte31 cce20) do
      assert required in names
    end
  end
end
