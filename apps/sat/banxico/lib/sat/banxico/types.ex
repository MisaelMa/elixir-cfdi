defmodule Sat.Banxico.Types do
  @moduledoc """
  Types for Banxico exchange rate client.
  """

  defmodule TipoCambio do
    @moduledoc false
    defstruct [:fecha, :moneda, :tipo_cambio]

    @type t :: %__MODULE__{
            fecha: String.t(),
            moneda: String.t(),
            tipo_cambio: float()
          }
  end

  defmodule Config do
    @moduledoc false
    defstruct [:api_token, timeout: 30_000]

    @type t :: %__MODULE__{
            api_token: String.t(),
            timeout: non_neg_integer()
          }
  end

  @type moneda :: :USD | :EUR | :GBP | :JPY | :CAD

  @serie_banxico %{
    USD: "SF43718",
    EUR: "SF46410",
    GBP: "SF46407",
    JPY: "SF46406",
    CAD: "SF60632"
  }

  @spec serie_banxico() :: %{moneda() => String.t()}
  def serie_banxico, do: @serie_banxico

  @spec resolve_serie(moneda()) :: {:ok, String.t()} | {:error, String.t()}
  def resolve_serie(moneda) do
    case Map.get(@serie_banxico, moneda) do
      nil -> {:error, "No hay serie Banxico configurada para la moneda: #{moneda}"}
      id -> {:ok, id}
    end
  end
end
