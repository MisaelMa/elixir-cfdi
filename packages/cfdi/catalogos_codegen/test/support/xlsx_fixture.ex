defmodule Cfdi.Catalogos.Codegen.Test.XlsxFixture do
  @moduledoc """
  Helper to generate a minimal valid `.xlsx` file for testing.

  An `.xlsx` is a ZIP containing these required XML files:
  - `[Content_Types].xml`
  - `_rels/.rels`
  - `xl/workbook.xml`
  - `xl/_rels/workbook.xml.rels`
  - `xl/sharedStrings.xml`
  - `xl/worksheets/sheet1.xml`
  - `xl/worksheets/sheet2.xml` (when two sheets)

  ## Regenerating the fixture

  Run from the package directory:

      mix run test/support/xlsx_fixture.ex

  Or from IEx:

      Code.require_file("test/support/xlsx_fixture.ex")
      Cfdi.Catalogos.Codegen.Test.XlsxFixture.write_tiny_xlsx("test/fixtures/tiny.xlsx")

  ## Fixture content (tiny.xlsx — matches tiny.xsd)

  The fixture mimics the real SAT catCFDI.xlsx structure where the row whose
  column A contains the simpleType name IS the column header row — data begins
  immediately after. There is NO separate "Clave/Descripcion" header row.

  The fixture has 2 sheets:

  ### Sheet `c_A` — 2 columns, 4 rows:
  - Row 1: ["c_A", "Nombre"]   (simpleType name in col A = column header row)
  - Row 2: ["01", "Alfa"]
  - Row 3: ["02", "Beta"]
  - Row 4: ["03", "Gamma"]

  ### Sheet `c_B` — 2 columns, 3 rows:
  - Row 1: ["c_B", "Nombre"]   (simpleType name in col A = column header row)
  - Row 2: ["X", "Equis"]
  - Row 3: ["Y", "Ye"]
  """

  # ─── Shared strings (all unique strings used in both sheets) ───────────────
  # Index: 0=c_A, 1=Nombre, 2=01, 3=Alfa, 4=02, 5=Beta, 6=03, 7=Gamma,
  #        8=c_B, 9=X, 10=Equis, 11=Y, 12=Ye
  @shared_strings_xml """
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="13" uniqueCount="13">
    <si><t>c_A</t></si>
    <si><t>Nombre</t></si>
    <si><t>01</t></si>
    <si><t>Alfa</t></si>
    <si><t>02</t></si>
    <si><t>Beta</t></si>
    <si><t>03</t></si>
    <si><t>Gamma</t></si>
    <si><t>c_B</t></si>
    <si><t>X</t></si>
    <si><t>Equis</t></si>
    <si><t>Y</t></si>
    <si><t>Ye</t></si>
  </sst>
  """

  # Sheet 1: c_A — simpleType header row + 3 data rows
  # Row 1: ["c_A", "Nombre"] — simpleType name in col A (auto-detect anchor)
  # Rows 2-4: data
  @sheet1_xml """
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
    <sheetData>
      <row r="1">
        <c r="A1" t="s"><v>0</v></c>
        <c r="B1" t="s"><v>1</v></c>
      </row>
      <row r="2">
        <c r="A2" t="s"><v>2</v></c>
        <c r="B2" t="s"><v>3</v></c>
      </row>
      <row r="3">
        <c r="A3" t="s"><v>4</v></c>
        <c r="B3" t="s"><v>5</v></c>
      </row>
      <row r="4">
        <c r="A4" t="s"><v>6</v></c>
        <c r="B4" t="s"><v>7</v></c>
      </row>
    </sheetData>
  </worksheet>
  """

  # Sheet 2: c_B — simpleType header row + 2 data rows
  @sheet2_xml """
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
    <sheetData>
      <row r="1">
        <c r="A1" t="s"><v>8</v></c>
        <c r="B1" t="s"><v>1</v></c>
      </row>
      <row r="2">
        <c r="A2" t="s"><v>9</v></c>
        <c r="B2" t="s"><v>10</v></c>
      </row>
      <row r="3">
        <c r="A3" t="s"><v>11</v></c>
        <c r="B3" t="s"><v>12</v></c>
      </row>
    </sheetData>
  </worksheet>
  """

  @content_types_xml """
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
    <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
    <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
    <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
  </Types>
  """

  @rels_xml """
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  </Relationships>
  """

  @workbook_xml """
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
    <sheets>
      <sheet name="c_A" sheetId="1" r:id="rId1"/>
      <sheet name="c_B" sheetId="2" r:id="rId2"/>
    </sheets>
  </workbook>
  """

  @workbook_rels_xml """
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
    <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
  </Relationships>
  """

  @doc "Build the tiny.xlsx as an in-memory binary (2 sheets: c_A and c_B matching tiny.xsd)."
  @spec build() :: binary()
  def build do
    files = [
      {~c"[Content_Types].xml", @content_types_xml},
      {~c"_rels/.rels", @rels_xml},
      {~c"xl/workbook.xml", @workbook_xml},
      {~c"xl/_rels/workbook.xml.rels", @workbook_rels_xml},
      {~c"xl/sharedStrings.xml", @shared_strings_xml},
      {~c"xl/worksheets/sheet1.xml", @sheet1_xml},
      {~c"xl/worksheets/sheet2.xml", @sheet2_xml}
    ]

    {:ok, {_name, binary}} = :zip.create(~c"tiny.xlsx", files, [:memory])
    binary
  end

  @doc "Write the tiny.xlsx fixture to the given path."
  @spec write_tiny_xlsx(Path.t()) :: :ok
  def write_tiny_xlsx(path \\ "test/fixtures/tiny.xlsx") do
    File.write!(path, build())
    IO.puts("Written: #{path}")
  end
end
