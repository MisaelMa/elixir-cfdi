defmodule Cfdi.Transform.Transform do
  @moduledoc """
  API fluente para generar la cadena original. Espejo de
  [`transform.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/transform/src/transform.ts).

      cadena =
        Cfdi.Transform.Transform.new()
        |> Cfdi.Transform.Transform.s("comprobante.xml")
        |> Cfdi.Transform.Transform.xsl("cadenaoriginal.xslt")
        |> Cfdi.Transform.Transform.run!()
  """

  alias Cfdi.Transform.{CadenaEngine, XsltParser}

  defstruct xml_path: nil, xml_content: nil, registry: nil

  @type t :: %__MODULE__{
          xml_path: String.t() | nil,
          xml_content: String.t() | nil,
          registry: map() | nil
        }

  @doc "Crea una instancia vacía."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Carga el archivo XML a transformar (equivale a `.s(file)` de Node)."
  @spec s(t(), String.t()) :: t()
  def s(%__MODULE__{} = t, xml_path) when is_binary(xml_path) do
    %{t | xml_path: xml_path, xml_content: File.read!(xml_path)}
  end

  @doc "Carga el XML directamente como string (sin archivo intermedio)."
  @spec xml_string(t(), String.t()) :: t()
  def xml_string(%__MODULE__{} = t, xml) when is_binary(xml) do
    %{t | xml_path: nil, xml_content: xml}
  end

  @doc "Carga la hoja XSLT (equivale a `.xsl(file)` de Node)."
  @spec xsl(t(), String.t()) :: t()
  def xsl(%__MODULE__{} = t, xsl_path) when is_binary(xsl_path) do
    {:ok, registry} = XsltParser.parse_file(xsl_path)
    %{t | registry: registry}
  end

  @doc "Alias de `xsl/2` (paridad con `.json(file)` de Node)."
  @spec json(t(), String.t()) :: t()
  def json(%__MODULE__{} = t, path), do: xsl(t, path)

  @doc "Sin efecto: paridad con `.warnings(_)` de Node."
  @spec warnings(t(), String.t()) :: t()
  def warnings(%__MODULE__{} = t, _type \\ "silent"), do: t

  @doc """
  Ejecuta la transformación. Devuelve `{:ok, cadena}` o `{:error, reason}`.
  """
  @spec run(t()) :: {:ok, String.t()} | {:error, term()}
  def run(%__MODULE__{registry: nil}), do: {:error, :xslt_not_loaded}
  def run(%__MODULE__{xml_content: nil}), do: {:error, :xml_not_loaded}

  def run(%__MODULE__{xml_content: xml, registry: registry}) do
    CadenaEngine.generate_cadena_original(xml, registry)
  end

  @doc "Como `run/1`, pero levanta `RuntimeError` si falla."
  @spec run!(t()) :: String.t()
  def run!(%__MODULE__{} = t) do
    case run(t) do
      {:ok, cadena} -> cadena
      {:error, :xslt_not_loaded} -> raise "XSLT not loaded. Call xsl/2 or json/2 first."
      {:error, :xml_not_loaded} -> raise "XML not loaded. Call s/2 first."
      {:error, reason} -> raise "Transform failed: #{inspect(reason)}"
    end
  end
end
