defmodule Cfdi.Schema do
  @moduledoc """
  Punto de entrada para cargar archivos XSD/JSON desde una ruta configurable
  (`:root` o `Application.get_env(:cfdi_schema, :schema_root)`).
  """

  alias Cfdi.Schema.Common.ProcessorFactory

  defstruct root: nil, opts: []

  @type t :: %__MODULE__{root: String.t() | nil, opts: keyword()}

  @doc """
  Crea un cargador con `opts` (`:root` directorio base de esquemas).
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) when is_list(opts) do
    root =
      Keyword.get(opts, :root) ||
        Application.get_env(:cfdi_schema, :schema_root) ||
        default_root()

    %__MODULE__{root: root, opts: opts}
  end

  defp default_root do
    Application.app_dir(:cfdi_schema, "priv/schemas")
  rescue
    ArgumentError -> "priv/schemas"
  end

  @doc """
  Lee el archivo `schema` (nombre relativo al root) y delega al procesador adecuado.
  """
  @spec load(t(), String.t()) :: {:ok, term()} | {:error, term()}
  def load(%__MODULE__{root: root} = loader, schema) when is_binary(schema) do
    path = Path.join(root, schema)

    case File.read(path) do
      {:ok, bin} ->
        case ProcessorFactory.detect(schema) do
          {:ok, kind} -> ProcessorFactory.processor_for(kind).process(bin, loader)
          {:error, _} = e -> e
        end

      {:error, :enoent} ->
        {:error, {:missing_schema, path}}

      {:error, _} = e ->
        e
    end
  end
end
