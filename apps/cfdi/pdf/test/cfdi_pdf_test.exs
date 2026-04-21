defmodule Cfdi.PdfTest do
  use ExUnit.Case, async: true

  test "pdf_version returns correct version" do
    assert Cfdi.Pdf.pdf_version() == "1.0"
  end

  test "OptionsPdf struct" do
    opts = %Cfdi.Pdf.Types.OptionsPdf{lugar_expedicion: "CDMX"}
    assert opts.lugar_expedicion == "CDMX"
  end

  test "Logo struct" do
    logo = %Cfdi.Pdf.Types.Logo{width: 100, height: 50, image: "base64data"}
    assert logo.width == 100
  end
end
