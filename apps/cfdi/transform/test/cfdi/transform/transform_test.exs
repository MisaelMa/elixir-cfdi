defmodule Cfdi.Transform.TransformTest do
  use ExUnit.Case

  test "run/1 error sin rutas" do
    assert {:error, :missing_xml_path} = Cfdi.Transform.Transform.new() |> Cfdi.Transform.Transform.run()
  end
end
