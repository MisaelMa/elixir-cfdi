defmodule Cfdi.Xml.Error do
  @moduledoc """
  Estructura de error para operaciones sobre XML CFDI.

  Mirror de `packages/cfdi/xml/src/common/error.ts` (clase `XmlError` +
  factory `CFDIError`).
  """

  defexception [:code, :message, :details, :name, :method]

  @type t :: %__MODULE__{
          code: String.t(),
          message: String.t(),
          details: any(),
          name: String.t(),
          method: String.t() | nil
        }

  @impl true
  def exception(opts) when is_list(opts) do
    %__MODULE__{
      code: Keyword.get(opts, :code, "error"),
      message: Keyword.get(opts, :message, ""),
      details: Keyword.get(opts, :details),
      name: Keyword.get(opts, :name, "XmlError"),
      method: Keyword.get(opts, :method)
    }
  end

  @impl true
  def message(%__MODULE__{name: name, message: msg, method: method}) do
    "#{name}: #{msg} #{method || ""}" |> String.trim_trailing()
  end

  @doc """
  Factory que envuelve cualquier error en un `%Cfdi.Xml.Error{}`.

  Acepta una `Exception`, un mapa con `:message`, o cualquier otro término
  que se stringifica.
  """
  @spec build(any(), keyword()) :: t()
  def build(e, opts \\ [])

  def build(%__MODULE__{} = e, opts) do
    %{
      e
      | name: Keyword.get(opts, :name, e.name),
        method: Keyword.get(opts, :method, e.method)
    }
  end

  def build(%{__exception__: true} = e, opts) do
    exception(
      message: Exception.message(e),
      code: "error",
      name: Keyword.get(opts, :name, "XmlError"),
      method: Keyword.get(opts, :method)
    )
  end

  def build(e, opts) do
    exception(
      message: to_string(e),
      code: "error",
      name: Keyword.get(opts, :name, "XmlError"),
      method: Keyword.get(opts, :method)
    )
  end
end
