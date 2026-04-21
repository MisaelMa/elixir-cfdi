defmodule Cfdi.Retenciones.Types do
  @moduledoc """
  Types for CFDI de Retenciones e información de pagos.
  """

  @retencion_pago_namespace_v1 "http://www.sat.gob.mx/esquemas/retencionpago/1"
  @retencion_pago_namespace_v2 "http://www.sat.gob.mx/esquemas/retencionpago/2"

  def namespace_v1, do: @retencion_pago_namespace_v1
  def namespace_v2, do: @retencion_pago_namespace_v2

  @type tipo_retencion :: :arrendamiento | :dividendos | :intereses | :fideicomiso | :enajenacion_acciones | :otro

  @tipo_retencion_values %{
    arrendamiento: "14",
    dividendos: "16",
    intereses: "17",
    fideicomiso: "18",
    enajenacion_acciones: "19",
    otro: "99"
  }

  def tipo_retencion_value(key), do: Map.fetch!(@tipo_retencion_values, key)

  defmodule EmisorRetencion do
    @moduledoc false
    defstruct [:rfc, :nom_den_raz_soc_e, :regimen_fiscal_e, :curp_e]
    @type t :: %__MODULE__{rfc: String.t(), nom_den_raz_soc_e: String.t() | nil, regimen_fiscal_e: String.t(), curp_e: String.t() | nil}
  end

  defmodule ReceptorNacional do
    @moduledoc false
    defstruct [:rfc_recep, :nom_den_raz_soc_r, :curp_r]
    @type t :: %__MODULE__{rfc_recep: String.t(), nom_den_raz_soc_r: String.t() | nil, curp_r: String.t() | nil}
  end

  defmodule ReceptorExtranjero do
    @moduledoc false
    defstruct [:num_reg_id_trib, :nom_den_raz_soc_r]
    @type t :: %__MODULE__{num_reg_id_trib: String.t() | nil, nom_den_raz_soc_r: String.t()}
  end

  defmodule ReceptorRetencion do
    @moduledoc false
    defstruct [:nacionalidad_r, :nacional, :extranjero]
    @type t :: %__MODULE__{nacionalidad_r: String.t(), nacional: ReceptorNacional.t() | nil, extranjero: ReceptorExtranjero.t() | nil}
  end

  defmodule PeriodoRetencion do
    @moduledoc false
    defstruct [:mes_ini, :mes_fin, :ejerc]
    @type t :: %__MODULE__{mes_ini: String.t(), mes_fin: String.t(), ejerc: String.t()}
  end

  defmodule TotalesRetencion do
    @moduledoc false
    defstruct [:monto_tot_operacion, :monto_tot_grav, :monto_tot_exent, :monto_tot_ret]
    @type t :: %__MODULE__{monto_tot_operacion: String.t(), monto_tot_grav: String.t(), monto_tot_exent: String.t(), monto_tot_ret: String.t()}
  end

  defmodule ComplementoRetencion do
    @moduledoc false
    defstruct [:inner_xml, :meta]
    @type t :: %__MODULE__{inner_xml: String.t(), meta: map() | nil}
  end

  defmodule Retencion20 do
    @moduledoc false
    defstruct [
      :cve_retenc,
      :desc_retenc,
      :fecha_exp,
      :lugar_exp_ret,
      :num_cert,
      :folio_int,
      :emisor,
      :receptor,
      :periodo,
      :totales,
      version: "2.0",
      complemento: []
    ]

    @type t :: %__MODULE__{
            version: String.t(),
            cve_retenc: String.t(),
            desc_retenc: String.t() | nil,
            fecha_exp: String.t(),
            lugar_exp_ret: String.t(),
            num_cert: String.t() | nil,
            folio_int: String.t() | nil,
            emisor: Cfdi.Retenciones.Types.EmisorRetencion.t(),
            receptor: Cfdi.Retenciones.Types.ReceptorRetencion.t(),
            periodo: Cfdi.Retenciones.Types.PeriodoRetencion.t(),
            totales: Cfdi.Retenciones.Types.TotalesRetencion.t(),
            complemento: [Cfdi.Retenciones.Types.ComplementoRetencion.t()]
          }
  end
end
