defmodule Sat.Diot.Types do
  @moduledoc """
  Types for DIOT declarations.
  """

  @type tipo_tercero :: :proveedor_nacional | :proveedor_extranjero | :proveedor_global

  @tipo_tercero_values %{
    proveedor_nacional: "04",
    proveedor_extranjero: "05",
    proveedor_global: "15"
  }

  @type tipo_operacion :: :profesionales_honorarios | :arrendamiento | :otros_con_iva | :otros_sin_iva

  @tipo_operacion_values %{
    profesionales_honorarios: "85",
    arrendamiento: "06",
    otros_con_iva: "03",
    otros_sin_iva: "04"
  }

  def tipo_tercero_value(key), do: Map.fetch!(@tipo_tercero_values, key)
  def tipo_operacion_value(key), do: Map.fetch!(@tipo_operacion_values, key)

  defmodule OperacionTercero do
    @moduledoc false
    defstruct [
      :tipo_tercero,
      :tipo_operacion,
      :rfc,
      :id_fiscal,
      :nombre_extranjero,
      :pais_residencia,
      :nacionalidad,
      monto_iva_16: 0.0,
      monto_iva_0: 0.0,
      monto_exento: 0.0,
      monto_retenido: 0.0,
      monto_iva_no_deduc: 0.0
    ]

    @type t :: %__MODULE__{
            tipo_tercero: Sat.Diot.Types.tipo_tercero(),
            tipo_operacion: Sat.Diot.Types.tipo_operacion(),
            rfc: String.t() | nil,
            id_fiscal: String.t() | nil,
            nombre_extranjero: String.t() | nil,
            pais_residencia: String.t() | nil,
            nacionalidad: String.t() | nil,
            monto_iva_16: float(),
            monto_iva_0: float(),
            monto_exento: float(),
            monto_retenido: float(),
            monto_iva_no_deduc: float()
          }
  end

  defmodule Declaracion do
    @moduledoc false
    defstruct [:rfc, :ejercicio, :periodo, operaciones: []]

    @type t :: %__MODULE__{
            rfc: String.t(),
            ejercicio: integer(),
            periodo: integer(),
            operaciones: [OperacionTercero.t()]
          }
  end
end
