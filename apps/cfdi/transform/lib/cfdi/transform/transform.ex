defmodule Cfdi.Transform.Transform do
  @moduledoc false

  alias Cfdi.Transform.{CadenaEngine, XsltParser}

  defstruct [:xml_path, :xsl_path]

  @type t :: %__MODULE__{
          xml_path: String.t() | nil,
          xsl_path: String.t() | nil
        }

  def new, do: %__MODULE__{}

  def source(%__MODULE__{} = t, path), do: %{t | xml_path: path}
  def xsl(%__MODULE__{} = t, path), do: %{t | xsl_path: path}

  @doc """
  Lee los archivos XML y XSLT, interpreta la hoja y genera la cadena original.
  """
  @spec run(t()) :: {:ok, String.t()} | {:error, term()}
  def run(%__MODULE__{xml_path: xml_path, xsl_path: xsl_path} = _t) do
    cond do
      is_nil(xml_path) -> {:error, :missing_xml_path}
      is_nil(xsl_path) -> {:error, :missing_xsl_path}
      true -> do_run(xml_path, xsl_path)
    end
  end

  defp do_run(xml_path, xsl_path) do
    with {:ok, xml} <- File.read(xml_path),
         {:ok, xsl} <- File.read(xsl_path),
         {:ok, registry} <- XsltParser.parse(xsl),
         {:ok, cadena} <- CadenaEngine.generate_cadena_original(xml, registry) do
      {:ok, cadena}
    else
      {:error, _} = e -> e
    end
  end
end
