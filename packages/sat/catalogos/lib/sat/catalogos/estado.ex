# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Estado do
  @moduledoc "Catálogo c_Estado del SAT (CFDI 4.0)."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "AGU", label: "Aguascalientes", deprecated: false},
    %{value: "BCN", label: "Baja California", deprecated: false},
    %{value: "BCS", label: "Baja California Sur", deprecated: false},
    %{value: "CAM", label: "Campeche", deprecated: false},
    %{value: "CHP", label: "Chiapas", deprecated: false},
    %{value: "CHH", label: "Chihuahua", deprecated: false},
    %{value: "COA", label: "Coahuila", deprecated: false},
    %{value: "COL", label: "Colima", deprecated: false},
    %{value: "DIF", label: "Distrito Federal", deprecated: true},
    %{value: "CMX", label: "Ciudad de México", deprecated: false},
    %{value: "DUR", label: "Durango", deprecated: false},
    %{value: "GUA", label: "Guanajuato", deprecated: false},
    %{value: "GRO", label: "Guerrero", deprecated: false},
    %{value: "HID", label: "Hidalgo", deprecated: false},
    %{value: "JAL", label: "Jalisco", deprecated: false},
    %{value: "MEX", label: "Estado de México", deprecated: false},
    %{value: "MIC", label: "Michoacán", deprecated: false},
    %{value: "MOR", label: "Morelos", deprecated: false},
    %{value: "NAY", label: "Nayarit", deprecated: false},
    %{value: "NLE", label: "Nuevo León", deprecated: false},
    %{value: "OAX", label: "Oaxaca", deprecated: false},
    %{value: "PUE", label: "Puebla", deprecated: false},
    %{value: "QUE", label: "Querétaro", deprecated: false},
    %{value: "ROO", label: "Quintana Roo", deprecated: false},
    %{value: "SLP", label: "San Luis Potosí", deprecated: false},
    %{value: "SIN", label: "Sinaloa", deprecated: false},
    %{value: "SON", label: "Sonora", deprecated: false},
    %{value: "TAB", label: "Tabasco", deprecated: false},
    %{value: "TAM", label: "Tamaulipas", deprecated: false},
    %{value: "TLA", label: "Tlaxcala", deprecated: false},
    %{value: "VER", label: "Veracruz", deprecated: false},
    %{value: "YUC", label: "Yucatán", deprecated: false},
    %{value: "ZAC", label: "Zacatecas", deprecated: false},
    %{value: "AL", label: "Alabama", deprecated: false},
    %{value: "AK", label: "Alaska", deprecated: false},
    %{value: "AZ", label: "Arizona", deprecated: false},
    %{value: "AR", label: "Arkansas", deprecated: false},
    %{value: "CA", label: "California", deprecated: false},
    %{value: "NC", label: "Carolina del Norte", deprecated: false},
    %{value: "SC", label: "Carolina del Sur", deprecated: false},
    %{value: "CO", label: "Colorado", deprecated: false},
    %{value: "CT", label: "Connecticut", deprecated: false},
    %{value: "ND", label: "Dakota del Norte", deprecated: false},
    %{value: "SD", label: "Dakota del Sur", deprecated: false},
    %{value: "DE", label: "Delaware", deprecated: false},
    %{value: "FL", label: "Florida", deprecated: false},
    %{value: "GA", label: "Georgia", deprecated: false},
    %{value: "HI", label: "Hawái", deprecated: false},
    %{value: "ID", label: "Idaho", deprecated: false},
    %{value: "IL", label: "Illinois", deprecated: false},
    %{value: "IN", label: "Indiana", deprecated: false},
    %{value: "IA", label: "Iowa", deprecated: false},
    %{value: "KS", label: "Kansas", deprecated: false},
    %{value: "KY", label: "Kentucky", deprecated: false},
    %{value: "LA", label: "Luisiana", deprecated: false},
    %{value: "ME", label: "Maine", deprecated: false},
    %{value: "MD", label: "Maryland", deprecated: false},
    %{value: "MA", label: "Massachusetts", deprecated: false},
    %{value: "MI", label: "Míchigan", deprecated: false},
    %{value: "MN", label: "Minnesota", deprecated: false},
    %{value: "MS", label: "Misisipi", deprecated: false},
    %{value: "MO", label: "Misuri", deprecated: false},
    %{value: "MT", label: "Montana", deprecated: false},
    %{value: "NE", label: "Nebraska", deprecated: false},
    %{value: "NV", label: "Nevada", deprecated: false},
    %{value: "NJ", label: "Nueva Jersey", deprecated: false},
    %{value: "NY", label: "Nueva York", deprecated: false},
    %{value: "NH", label: "Nuevo Hampshire", deprecated: false},
    %{value: "NM", label: "Nuevo México", deprecated: false},
    %{value: "OH", label: "Ohio", deprecated: false},
    %{value: "OK", label: "Oklahoma", deprecated: false},
    %{value: "OR", label: "Oregón", deprecated: false},
    %{value: "PA", label: "Pensilvania", deprecated: false},
    %{value: "RI", label: "Rhode Island", deprecated: false},
    %{value: "TN", label: "Tennessee", deprecated: false},
    %{value: "TX", label: "Texas", deprecated: false},
    %{value: "UT", label: "Utah", deprecated: false},
    %{value: "VT", label: "Vermont", deprecated: false},
    %{value: "VA", label: "Virginia", deprecated: false},
    %{value: "WV", label: "Virginia Occidental", deprecated: false},
    %{value: "WA", label: "Washington", deprecated: false},
    %{value: "WI", label: "Wisconsin", deprecated: false},
    %{value: "WY", label: "Wyoming", deprecated: false},
    %{value: "ON", label: "Ontario ", deprecated: false},
    %{value: "QC", label: " Quebec ", deprecated: false},
    %{value: "NS", label: " Nueva Escocia", deprecated: false},
    %{value: "NB", label: "Nuevo Brunswick ", deprecated: false},
    %{value: "MB", label: " Manitoba", deprecated: false},
    %{value: "BC", label: " Columbia Británica", deprecated: false},
    %{value: "PE", label: " Isla del Príncipe Eduardo", deprecated: false},
    %{value: "SK", label: " Saskatchewan", deprecated: false},
    %{value: "AB", label: " Alberta", deprecated: false},
    %{value: "NL", label: " Terranova y Labrador", deprecated: false},
    %{value: "NT", label: " Territorios del Noroeste", deprecated: false},
    %{value: "YT", label: " Yukón", deprecated: false},
    %{value: "UN", label: " Nunavut", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.value == code))
  def valid?(_), do: false

  @doc "Busca una entrada por su código."
  def from_code(code) when is_binary(code) do
    case Enum.find(@entries, &(&1.value == code)) do
      nil -> :error
      entry -> {:ok, entry}
    end
  end
end
