defmodule Sat.Catalogos.Codegen.Catalogs do
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
      # Fuente del catálogo: `:cfdi` (catCFDI, default) o `:nomina` (catNomina,
      # complemento de Nómina 1.2). Afecta el encabezado y el moduledoc generados.
      source: :cfdi,
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
            source: :cfdi | :nomina,
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
        module_name: Sat.Catalogos.FormaPago,
        file_name: "forma_pago.ex",
        variant: :with_atoms,
        overrides_file: "forma_pago.exs",
        code_pad_start: 2
      },
      # c_MetodoPago: XLSX codes are "PUE","PPD" — already strings, no padding
      %Spec{
        simpletype: "c_MetodoPago",
        module_name: Sat.Catalogos.MetodoPago,
        file_name: "metodo_pago.ex",
        variant: :with_atoms,
        overrides_file: "metodo_pago.exs",
        code_pad_start: 0
      },
      # c_TipoDeComprobante: XLSX codes are "I","E","T","N","P" — single-letter strings
      %Spec{
        simpletype: "c_TipoDeComprobante",
        module_name: Sat.Catalogos.TipoComprobante,
        file_name: "tipo_comprobante.ex",
        variant: :with_atoms,
        overrides_file: "tipo_comprobante.exs",
        code_pad_start: 0
      },
      # c_Impuesto: XLSX codes are "1","2","3"; XSD codes are "001","002","003"
      %Spec{
        simpletype: "c_Impuesto",
        module_name: Sat.Catalogos.Impuesto,
        file_name: "impuesto.ex",
        variant: :with_atoms,
        overrides_file: "impuesto.exs",
        code_pad_start: 3
      },
      # c_UsoCFDI: XLSX codes are "G01","S01","CN01" — already padded strings
      %Spec{
        simpletype: "c_UsoCFDI",
        module_name: Sat.Catalogos.UsoCFDI,
        file_name: "uso_cfdi.ex",
        variant: :with_atoms,
        overrides_file: "uso_cfdi.exs",
        code_pad_start: 0
      },
      # c_Exportacion: XLSX codes are "01","02","03" — already padded strings
      %Spec{
        simpletype: "c_Exportacion",
        module_name: Sat.Catalogos.Exportacion,
        file_name: "exportacion.ex",
        variant: :with_atoms,
        overrides_file: "exportacion.exs",
        code_pad_start: 0
      },
      # c_Moneda: XLSX codes are "AED","AFN",... — 3-letter ISO codes, no padding
      %Spec{
        simpletype: "c_Moneda",
        module_name: Sat.Catalogos.Moneda,
        file_name: "moneda.ex",
        variant: :with_atoms,
        overrides_file: "moneda.exs",
        code_pad_start: 0
      },

      # No-atom (variant :strings_only)
      # c_Periodicidad: XLSX codes are "01","02",... — already padded strings
      %Spec{
        simpletype: "c_Periodicidad",
        module_name: Sat.Catalogos.Periodicidad,
        file_name: "periodicidad.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_Meses: XLSX codes are "01","02",... — already padded strings
      %Spec{
        simpletype: "c_Meses",
        module_name: Sat.Catalogos.Meses,
        file_name: "meses.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_TipoRelacion: XLSX codes are "1","2",...; XSD codes are "01","02",...
      # Codes "08" and "09" are in XSD but not in XLSX (deprecated).
      %Spec{
        simpletype: "c_TipoRelacion",
        module_name: Sat.Catalogos.TipoRelacion,
        file_name: "tipo_relacion.ex",
        variant: :strings_only,
        overrides_file: "tipo_relacion.exs",
        code_pad_start: 2
      },
      # c_ObjetoImp: XLSX codes are "01","02",... — already padded strings
      %Spec{
        simpletype: "c_ObjetoImp",
        module_name: Sat.Catalogos.ObjetoImp,
        file_name: "objeto_imp.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_TipoFactor: XLSX codes are "Tasa","Cuota","Exento" — text strings.
      # This sheet has NO description column (col B is fecha inicio vigencia).
      # The code itself IS the human-readable label, so label_column: 0 reuses col A.
      %Spec{
        simpletype: "c_TipoFactor",
        module_name: Sat.Catalogos.TipoFactor,
        file_name: "tipo_factor.ex",
        variant: :strings_only,
        code_pad_start: 0,
        label_column: 0
      },
      # c_Pais: XLSX codes are "AFG","MEX",... — 3-letter ISO codes
      %Spec{
        simpletype: "c_Pais",
        module_name: Sat.Catalogos.Pais,
        file_name: "pais.ex",
        variant: :strings_only,
        code_pad_start: 0
      },
      # c_Estado: XLSX columns: A=code, B=c_Pais (country code), C=state name, D=inicio, E=fin.
      # label_column: 2 (0-based) picks column C (the state name), skipping the country code in B.
      # Code "DIF" (Distrito Federal) is in XSD but absent from XLSX — supplied via override.
      %Spec{
        simpletype: "c_Estado",
        module_name: Sat.Catalogos.Estado,
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
        module_name: Sat.Catalogos.RegimenFiscal,
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

  @doc """
  Especificaciones de los catálogos del complemento de NÓMINA (Nomina 1.2).

  Se generan desde una fuente DISTINTA a catCFDI: `catNomina.xsd` + `catNomina.xlsx`.
  Todos son `:strings_only` (código → descripción). Cada hoja del xlsx coincide
  con el nombre del simpleType (c_TipoPercepcion, etc.).

      mix sat.catalogos.generate --source nomina
  """
  @spec nomina_specs() :: [Spec.t()]
  def nomina_specs do
    spec = fn simpletype, module_name, file_name, code_pad_start ->
      %Spec{
        simpletype: simpletype,
        module_name: module_name,
        file_name: Path.join("complementos/nomina", file_name),
        variant: :strings_only,
        sheet_name: simpletype,
        source: :nomina,
        code_pad_start: code_pad_start
      }
    end

    [
      spec.("c_TipoPercepcion", Sat.Catalogos.Complementos.Nomina.TipoPercepcion, "tipo_percepcion.ex", 3),
      spec.("c_TipoDeduccion", Sat.Catalogos.Complementos.Nomina.TipoDeduccion, "tipo_deduccion.ex", 3),
      spec.("c_TipoOtroPago", Sat.Catalogos.Complementos.Nomina.TipoOtroPago, "tipo_otro_pago.ex", 3),
      spec.("c_TipoNomina", Sat.Catalogos.Complementos.Nomina.TipoNomina, "tipo_nomina.ex", 0),
      spec.("c_TipoContrato", Sat.Catalogos.Complementos.Nomina.TipoContrato, "tipo_contrato.ex", 2),
      spec.("c_TipoJornada", Sat.Catalogos.Complementos.Nomina.TipoJornada, "tipo_jornada.ex", 2),
      spec.("c_TipoRegimen", Sat.Catalogos.Complementos.Nomina.TipoRegimen, "tipo_regimen.ex", 2),
      spec.("c_PeriodicidadPago", Sat.Catalogos.Complementos.Nomina.PeriodicidadPago, "periodicidad_pago.ex", 2),
      spec.("c_RiesgoPuesto", Sat.Catalogos.Complementos.Nomina.RiesgoPuesto, "riesgo_puesto.ex", 1),
      spec.("c_Banco", Sat.Catalogos.Complementos.Nomina.Banco, "banco.ex", 3),
      spec.("c_OrigenRecurso", Sat.Catalogos.Complementos.Nomina.OrigenRecurso, "origen_recurso.ex", 0),
      spec.("c_TipoHoras", Sat.Catalogos.Complementos.Nomina.TipoHoras, "tipo_horas.ex", 2),
      spec.("c_TipoIncapacidad", Sat.Catalogos.Complementos.Nomina.TipoIncapacidad, "tipo_incapacidad.ex", 2)
    ]
  end
end
