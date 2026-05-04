defmodule Cfdi.ExpresionesTest do
  use ExUnit.Case, async: true

  alias Cfdi.Expresiones.Transform

  test "run generates pipe-separated expression" do
    xml = %{
      "cfdi:Comprobante" => %{
        "_attributes" => %{
          "Version" => "4.0",
          "Total" => "1000.00"
        },
        "cfdi:Emisor" => %{
          "_attributes" => %{
            "Rfc" => "AAA010101AAA",
            "Nombre" => "Test"
          }
        }
      }
    }

    result = Transform.run(xml)
    assert String.starts_with?(result, "||")
    assert String.ends_with?(result, "||")
    assert result =~ "4.0"
    assert result =~ "1000.00"
  end
end
