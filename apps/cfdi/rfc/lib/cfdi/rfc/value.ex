defmodule Cfdi.Rfc.Value do
  @moduledoc """
  RFC value object with validation and helper methods.
  """

  alias Cfdi.Rfc
  alias Cfdi.Rfc.Constants

  defstruct [:value]

  @type t :: %__MODULE__{value: String.t()}

  @special_rfc_values Map.keys(Constants.special_cases())

  @spec of(String.t()) :: {:ok, t()} | {:error, String.t()}
  def of(rfc) do
    normalized = rfc |> to_string() |> String.trim() |> String.upcase()

    if normalized in @special_rfc_values do
      {:ok, %__MODULE__{value: normalized}}
    else
      result = Rfc.validate(rfc)

      if result.is_valid do
        {:ok, %__MODULE__{value: result.rfc}}
      else
        {:error, "'#{rfc}' is not a valid RFC"}
      end
    end
  end

  @spec of!(String.t()) :: t()
  def of!(rfc) do
    case of(rfc) do
      {:ok, v} -> v
      {:error, msg} -> raise ArgumentError, msg
    end
  end

  @spec parse(String.t()) :: t() | nil
  def parse(rfc) do
    case of(rfc) do
      {:ok, v} -> v
      {:error, _} -> nil
    end
  end

  @spec valid?(String.t()) :: boolean()
  def valid?(rfc) do
    normalized = rfc |> to_string() |> String.trim() |> String.upcase()

    if normalized in @special_rfc_values do
      true
    else
      Rfc.validate(rfc).is_valid
    end
  end

  @spec to_string_value(t()) :: String.t()
  def to_string_value(%__MODULE__{value: v}), do: v

  defimpl String.Chars do
    def to_string(%{value: v}), do: v
  end

  @spec fisica?(t()) :: boolean()
  def fisica?(%__MODULE__{value: v}) do
    byte_size(v) == 13 && !generic?(v) && !foreign?(v)
  end

  @spec moral?(t()) :: boolean()
  def moral?(%__MODULE__{value: v}), do: byte_size(v) == 12

  @spec generic?(t() | String.t()) :: boolean()
  def generic?(%__MODULE__{value: v}), do: v == "XAXX010101000"
  def generic?(v) when is_binary(v), do: v == "XAXX010101000"

  @spec foreign?(t() | String.t()) :: boolean()
  def foreign?(%__MODULE__{value: v}), do: v == "XEXX010101000"
  def foreign?(v) when is_binary(v), do: v == "XEXX010101000"

  @spec obtain_date(t()) :: Date.t() | nil
  def obtain_date(%__MODULE__{value: v}) do
    if generic?(v) || foreign?(v) do
      nil
    else
      date_str =
        if byte_size(v) == 12,
          do: String.slice(v, 3, 6),
          else: String.slice(v, 4, 6)

      year = String.to_integer(String.slice(date_str, 0, 2))
      month = String.to_integer(String.slice(date_str, 2, 2))
      day = String.to_integer(String.slice(date_str, 4, 2))

      current_year = Date.utc_today().year |> rem(100)
      century = if year <= current_year, do: 2000, else: 1900

      case Date.new(century + year, month, day) do
        {:ok, date} -> date
        _ -> nil
      end
    end
  rescue
    _ -> nil
  end

  @spec equals?(t(), t()) :: boolean()
  def equals?(%__MODULE__{value: a}, %__MODULE__{value: b}), do: a == b
end
