defmodule Sat.Contabilidad.Types do
  @moduledoc """
  Types for Contabilidad Electrónica XML generation.
  """

  @type tipo_envio :: :normal | :complementaria
  @type tipo_ajuste :: :cierre | :apertura
  @type naturaleza_cuenta :: :deudora | :acreedora
  @type version :: :"1.1" | :"1.3"

  def tipo_envio_value(:normal), do: "N"
  def tipo_envio_value(:complementaria), do: "C"

  def naturaleza_cuenta_value(:deudora), do: "D"
  def naturaleza_cuenta_value(:acreedora), do: "A"

  defmodule ContribuyenteInfo do
    @moduledoc false
    defstruct [:rfc, :mes, :anio, :tipo_envio]

    @type t :: %__MODULE__{
            rfc: String.t(),
            mes: String.t(),
            anio: integer(),
            tipo_envio: Sat.Contabilidad.Types.tipo_envio()
          }
  end

  defmodule CuentaBalanza do
    @moduledoc false
    defstruct [:num_cta, :saldo_ini, :debe, :haber, :saldo_fin]

    @type t :: %__MODULE__{
            num_cta: String.t(),
            saldo_ini: float(),
            debe: float(),
            haber: float(),
            saldo_fin: float()
          }
  end

  defmodule CuentaCatalogo do
    @moduledoc false
    defstruct [:cod_agrup, :num_cta, :desc, :sub_cta_de, :nivel, :natur]

    @type t :: %__MODULE__{
            cod_agrup: String.t(),
            num_cta: String.t(),
            desc: String.t(),
            sub_cta_de: String.t() | nil,
            nivel: integer(),
            natur: Sat.Contabilidad.Types.naturaleza_cuenta()
          }
  end

  defmodule PolizaDetalle do
    @moduledoc false
    defstruct [:num_unidad, :concepto, :debe, :haber, :num_cta]

    @type t :: %__MODULE__{
            num_unidad: String.t(),
            concepto: String.t(),
            debe: float(),
            haber: float(),
            num_cta: String.t()
          }
  end

  defmodule Poliza do
    @moduledoc false
    defstruct [:num_poliza, :fecha, :concepto, detalle: []]

    @type t :: %__MODULE__{
            num_poliza: String.t(),
            fecha: String.t(),
            concepto: String.t(),
            detalle: [PolizaDetalle.t()]
          }
  end

  defmodule TransaccionAuxiliar do
    @moduledoc false
    defstruct [:fecha, :num_poliza, :concepto, :debe, :haber]

    @type t :: %__MODULE__{
            fecha: String.t(),
            num_poliza: String.t(),
            concepto: String.t(),
            debe: float(),
            haber: float()
          }
  end

  defmodule CuentaAuxiliar do
    @moduledoc false
    defstruct [:num_cta, :des_cta, :saldo_ini, :saldo_fin, transacciones: []]

    @type t :: %__MODULE__{
            num_cta: String.t(),
            des_cta: String.t(),
            saldo_ini: float(),
            saldo_fin: float(),
            transacciones: [TransaccionAuxiliar.t()]
          }
  end
end
