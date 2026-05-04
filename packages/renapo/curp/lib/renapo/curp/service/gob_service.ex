defmodule Renapo.Curp.Service.GobService do
  @moduledoc false

  @doc """
  Placeholder for RENAPO *consulta por CURP*; set base URL / credentials when available.
  """
  @spec find_by_curp(String.t()) :: {:ok, map()} | {:error, String.t()}
  def find_by_curp(_curp) do
    {:error, "GobService.find_by_curp/1 not configured"}
  end

  @doc """
  Placeholder for RENAPO *consulta por datos*.
  """
  @spec find_by_data(map()) :: {:ok, map()} | {:error, String.t()}
  def find_by_data(_payload) do
    {:error, "GobService.find_by_data/1 not configured"}
  end

  @doc """
  Fetches a PDF (Base64) for a CURP record when the upstream exposes it.
  """
  @spec get_base64_pdf(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_base64_pdf(_id) do
    {:error, "GobService.get_base64_pdf/1 not configured"}
  end

  @doc """
  Decodes Base64 PDF and writes to `path`.
  """
  @spec save_pdf(Path.t(), String.t()) :: :ok | {:error, String.t()}
  def save_pdf(path, b64) when is_binary(b64) do
    case Base.decode64(b64) do
      {:ok, bin} ->
        case File.write(path, bin) do
          :ok -> :ok
          {:error, reason} -> {:error, inspect(reason)}
        end

      :error ->
        {:error, "invalid base64"}
    end
  end
end
