defmodule Cfdi.Catalogos.Codegen.Catalogs do
  @moduledoc """
  Static list of the 15 catalog specifications for CFDI 4.0.

  Each `Spec` struct describes one catalog: the simpleType name from the XSD,
  the generated Elixir module name, the output file name, and the rendering
  variant to use.

  The 6 large catalogs (ClaveProdServ, ClaveUnidad, CodigoPostal, Colonia,
  Localidad, Municipio) are intentionally excluded — they belong in a future
  lookup-service package.
  """

  defmodule Spec do
    @moduledoc "Specification for a single catalog to be generated."

    @enforce_keys [:simpletype, :module_name, :file_name, :variant]
    defstruct [
      :simpletype,
      :module_name,
      :file_name,
      :variant,
      sheet_name: nil,
      extra_columns: [],
      overrides_file: nil,
      # When > 0, numeric-looking codes (all-digit strings) are zero-padded to this length.
      # Example: c_FormaPago has code_pad_start: 2 → "1" becomes "01", "12" stays "12".
      # When 0, no padding is applied.
      code_pad_start: 0,
      # Zero-based column index of the human-readable label in XLSX data rows.
      # Default: 1 (column B, the standard SAT layout).
      # Set to 2 for c_Estado (col B = c_Pais country code, col C = state name).
      # Set to 0 for catalogs where the code itself IS the label (e.g., c_TipoFactor).
      label_column: 1
    ]

    @type t :: %__MODULE__{
            simpletype: String.t(),
            module_name: module(),
            file_name: String.t(),
            variant: :with_atoms | :strings_only | :regimen_fiscal,
            sheet_name: String.t() | nil,
            extra_columns: keyword(non_neg_integer()),
            overrides_file: String.t() | nil,
            code_pad_start: non_neg_integer(),
            label_column: non_neg_integer()
          }
  end

  @doc """
  Returns the list of 15 catalog specifications in XSD code order.

  Order matches the SAT XSD ordering for diff stability.
  """
  @spec specs() :: [Spec.t()]
  def specs do
    [
      # Atom-bearing (variant :with_atoms)
      # c_FormaPago: XLSX codes are "1","2",...; XSD codes are "01","02",...
      %Spec{
        simpletype: "c_FormaPago",
        module_name: Cfdi.Catalogos.FormaPago,
        file_name: "forma_pago.ex",
        variant: :with_atoms,
        overrides_file: "forma_pago.exs",
        code_pad_start: 2
      },
      # c_MetodoPago: XLSX codes are "PUE","PPD" — already strings, no padding
      %Spec{
        simpletype: "c_MetodoPago",
        module_name: Cfdi.Catalogos.MetodoPago,
        file_name: "metodo_pago.ex",
        variant: :with_atoms,
        overrides_file: "metodo_pago.exs",
        code_pad_start: 0
      },
      # c_TipoDeComprobante: XLSX codes are "I","E","T","N","P" — single-letter strings
      %Spec{
        simpletype: "c_TipoDeComprobante",
        module_name: Cfdi.Catalogos.TipoComprobante,
        file_name: "tipo_comprobante.ex",
        variant: :with_atoms,
        overrides_file: "tipo_comprobante.exs",
        code_pad_start: 0
      },
      # c_Impuesto: XLSX codes are "1","2","3"; XSD codes are "001","002","003"
      %Spec{
        simpletype: "c_Impuesto",
        module_name: Cfdi.Catalogos.Impuesto,
        file_name: "impuesto.ex",
        variant: :with_atoms,
        overrides_file: "impuesto.exs",
        code_pad_start: 3
      },
      # c_UsoCFDI: XLSX codes are "G01","S01","CN01" — already padded strings
      %Spec{
        simpletype: "c_UsoCFDI",
        module_name: Cfdi.Catalogos.UsoCFDI,
        file_name: "uso_cfdi.ex",
        variant: :with_atoms,
        overrides_file: "uso_cfdi.exs",
        code_pad_start: 0
      },
      # c_Exportacion: XLSX codes are "01","02","03" — already padded strings
      %Spec{
        simpletype: "c_Exportacion",
        module_name: Cfdi.Catalogos.Exportacion,
        file_name: "exportacion.ex",
        variant: :with_atoms,
        overrides_file: "exportacion.exs",
        code_pad_start: 0
      },
      # c_Moneda: XLSX codes are "AED","AFN",... — 3-letter ISO codes, no padding
      %Spec{
        simpletype: "c_Moneda",
        module_name: Cfdi.Catalogos.Moneda,
        file_name: "moneda.ex",
        variant: :with_atoms,
        overrides_file: "moneda.exs",
        code_pad_start: 0
      },

      # No-atom (variant :strings_only)
      # c_Periodicidad: XLSX codes are "01","02",... — already padded strings
      %Spec{
        simpletype: "c_Periodicidad",
        module_name: Cfdi.Catalogos.Periodicidad,
        file_name: "periodicidad.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_Meses: XLSX codes are "01","02",... — already padded strings
      %Spec{
        simpletype: "c_Meses",
        module_name: Cfdi.Catalogos.Meses,
        file_name: "meses.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_TipoRelacion: XLSX codes are "1","2",...; XSD codes are "01","02",...
      # Codes "08" and "09" are in XSD but not in XLSX (deprecated).
      %Spec{
        simpletype: "c_TipoRelacion",
        module_name: Cfdi.Catalogos.TipoRelacion,
        file_name: "tipo_relacion.ex",
        variant: :strings_only,
        overrides_file: "tipo_relacion.exs",
        code_pad_start: 2
      },
      # c_ObjetoImp: XLSX codes are "01","02",... — already padded strings
      %Spec{
        simpletype: "c_ObjetoImp",
        module_name: Cfdi.Catalogos.ObjetoImp,
        file_name: "objeto_imp.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_TipoFactor: XLSX codes are "Tasa","Cuota","Exento" — text strings.
      # This sheet has NO description column (col B is fecha inicio vigencia).
      # The code itself IS the human-readable label, so label_column: 0 reuses col A.
      %Spec{
        simpletype: "c_TipoFactor",
        module_name: Cfdi.Catalogos.TipoFactor,
        file_name: "tipo_factor.ex",
        variant: :strings_only,
        code_pad_start: 0,
        label_column: 0
      },
      # c_Pais: XLSX codes are "AFG","MEX",... — 3-letter ISO codes
      %Spec{
        simpletype: "c_Pais",
        module_name: Cfdi.Catalogos.Pais,
        file_name: "pais.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_Estado: XLSX columns: A=code, B=c_Pais (country code), C=state name, D=inicio, E=fin.
      # label_column: 2 (0-based) picks column C (the state name), skipping the country code in B.
      # Code "DIF" (Distrito Federal) is in XSD but absent from XLSX — supplied via override.
      %Spec{
        simpletype: "c_Estado",
        module_name: Cfdi.Catalogos.Estado,
        file_name: "estado.ex",
        variant: :strings_only,
        overrides_file: "estado.exs",
        code_pad_start: 0,
        label_column: 2
      },

      # Special (variant :regimen_fiscal)
      # c_RegimenFiscal: XLSX codes are "601","603",... — already 3-digit strings
      # Real XLSX column layout (0-based in data row):
      #   0=code, 1=label, 2=persona_fisica, 3=persona_moral, 4=inicio_vigencia, 5=fin_vigencia
      # extra_columns uses 1-based indices (code_index converts via col_index - 1):
      %Spec{
        simpletype: "c_RegimenFiscal",
        module_name: Cfdi.Catalogos.RegimenFiscal,
        file_name: "regimen_fiscal.ex",
        variant: :regimen_fiscal,
        overrides_file: "regimen_fiscal.exs",
        code_pad_start: 0,
        extra_columns: [
          persona_fisica: 3,
          persona_moral: 4,
          inicio_vigencia: 5,
          fin_vigencia: 6
        ]
      }
    ]
  end
end
