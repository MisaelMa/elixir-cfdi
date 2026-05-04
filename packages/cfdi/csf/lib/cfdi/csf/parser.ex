defmodule Cfdi.Csf.Parser do
  @moduledoc false

  defmodule CsfData do
    @moduledoc false
    defstruct [:rfc, :curp, :nombre, :regimen, :calle, :colonia, :municipio, :estado, :cp, :raw]

    @type t :: %__MODULE__{
            rfc: String.t() | nil,
            curp: String.t() | nil,
            nombre: String.t() | nil,
            regimen: String.t() | nil,
            calle: String.t() | nil,
            colonia: String.t() | nil,
            municipio: String.t() | nil,
            estado: String.t() | nil,
            cp: String.t() | nil,
            raw: String.t()
          }
  end

  @rfc_re ~r/\b([A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3})\b/u
  @curp_re ~r/\b([A-Z]{4}\d{6}[HM][A-Z]{5}[0-9A-Z][0-9])\b/u
  @cp_re ~r/\b(\d{5})\b/

  @spec csf(String.t()) :: {:ok, CsfData.t()} | {:error, String.t()}
  def csf(text) when is_binary(text) do
    normalized = String.replace(text, "\r\n", "\n")

    rfc = first_capture(normalized, @rfc_re)
    curp = first_capture(normalized, @curp_re)

    {:ok,
     %CsfData{
       rfc: rfc,
       curp: curp,
       nombre: extract_line_after(normalized, "Nombre"),
       regimen: extract_line_after(normalized, "Régimen"),
       calle: extract_line_after(normalized, "Nombre de la vialidad"),
       colonia: extract_line_after(normalized, "Colonia"),
       municipio: extract_line_after(normalized, "Municipio"),
       estado: extract_line_after(normalized, "Entidad federativa"),
       cp: first_capture(normalized, @cp_re),
       raw: normalized
     }}
  end

  defp first_capture(hay, re) do
    case Regex.run(re, hay) do
      [_, cap] -> cap
      _ -> nil
    end
  end

  defp extract_line_after(hay, label) do
    case Regex.run(~r/#{Regex.escape(label)}[:\s]+([^\n]+)/iu, hay) do
      [_, v] -> String.trim(v)
      _ -> nil
    end
  end
end
