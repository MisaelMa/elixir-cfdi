defmodule Cfdi.Concepto do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Concepto", accepts_children: true

  alias Cfdi.Concepto.{ACuentaTerceros, Complemento, CuentaPredial, InformacionAduanera, Parte}

  attribute :ClaveProdServ, :string
  attribute :NoIdentificacion, :string
  attribute :Cantidad, :string
  attribute :ClaveUnidad, :string
  attribute :Unidad, :string
  attribute :Descripcion, :string
  attribute :ValorUnitario, :string
  attribute :Importe, :string
  attribute :Descuento, :string
  attribute :ObjetoImp, :string

  child :traslados, :list
  child :retenciones, :list
  child :informacion_aduanera, :list
  child :cuenta_predial, :map
  child :a_cuenta_terceros, :map
  child :parte, :list
  child :complemento, :map

  @doc """
  Añade un `cfdi:Traslado` al concepto.
  """
  def add_traslado(c, %Cfdi.Traslado{} = t) when is_struct(c, __MODULE__) do
    list = (c.traslados || []) ++ [t]
    %{c | traslados: list}
  end

  def add_traslado(c, data) when is_struct(c, __MODULE__) and is_map(data) do
    add_traslado(c, struct(Cfdi.Traslado, data))
  end

  @doc """
  Añade una `cfdi:Retencion` al concepto.
  """
  def add_retencion(c, %Cfdi.Retencion{} = r) when is_struct(c, __MODULE__) do
    list = (c.retenciones || []) ++ [r]
    %{c | retenciones: list}
  end

  def add_retencion(c, data) when is_struct(c, __MODULE__) and is_map(data) do
    add_retencion(c, struct(Cfdi.Retencion, data))
  end

  @doc """
  Añade un `cfdi:InformacionAduanera` al concepto.
  """
  def add_informacion_aduanera(c, %InformacionAduanera{} = ia) when is_struct(c, __MODULE__) do
    list = (c.informacion_aduanera || []) ++ [ia]
    %{c | informacion_aduanera: list}
  end

  def add_informacion_aduanera(c, pedimento) when is_struct(c, __MODULE__) and is_binary(pedimento) do
    add_informacion_aduanera(c, %InformacionAduanera{NumeroPedimento: pedimento})
  end

  @doc """
  Establece la `cfdi:CuentaPredial` del concepto.
  """
  def set_cuenta_predial(c, %CuentaPredial{} = cp) when is_struct(c, __MODULE__) do
    %{c | cuenta_predial: cp}
  end

  def set_cuenta_predial(c, numero) when is_struct(c, __MODULE__) and is_binary(numero) do
    set_cuenta_predial(c, %CuentaPredial{Numero: numero})
  end

  @doc """
  Establece `cfdi:ACuentaTerceros` en el concepto.
  """
  def set_a_cuenta_terceros(c, %ACuentaTerceros{} = t) when is_struct(c, __MODULE__) do
    %{c | a_cuenta_terceros: t}
  end

  def set_a_cuenta_terceros(c, data) when is_struct(c, __MODULE__) and is_map(data) do
    set_a_cuenta_terceros(c, struct(ACuentaTerceros, data))
  end

  @doc """
  Añade un `cfdi:Parte` al concepto.
  """
  def add_parte(c, %Parte{} = p) when is_struct(c, __MODULE__) do
    list = (c.parte || []) ++ [p]
    %{c | parte: list}
  end

  def add_parte(c, data) when is_struct(c, __MODULE__) and is_map(data) do
    add_parte(c, struct(Parte, data))
  end

  @doc """
  Añade un `cfdi:InformacionAduanera` a la última `cfdi:Parte` del concepto.

  Si el concepto no tiene partes todavía, es un no-op: replica la semántica
  del `setParteInformacionAduanera` del paquete Node, que solo imprime una
  advertencia.
  """
  def add_parte_informacion_aduanera(c, pedimento) when is_struct(c, __MODULE__) and is_binary(pedimento) do
    case c.parte do
      nil ->
        c

      [] ->
        c

      list ->
        {init, [last]} = Enum.split(list, -1)
        updated = Parte.add_informacion_aduanera(last, pedimento)
        %{c | parte: init ++ [updated]}
    end
  end

  @doc """
  Añade un complemento (struct `Cfdi.Complementos.*`) al `cfdi:ComplementoConcepto`.

  El struct debe implementar `Cfdi.Complementos.Complemento` — el propio
  complemento expone su `key`, `xmlns` y carga útil.
  """
  def add_complemento(c, complemento)
      when is_struct(c, __MODULE__) and is_struct(complemento) do
    cc = c.complemento || %Complemento{}
    %{c | complemento: Complemento.add(cc, complemento)}
  end

  @doc false
  def to_map(nil, _opts), do: nil

  def to_map(c, opts) when is_struct(c, __MODULE__) and is_list(opts) do
    ns? = Keyword.get(opts, :ns, true)
    wrap? = Keyword.get(opts, :wrap, true)

    attrs =
      c
      |> Map.from_struct()
      |> Map.take(__xml__(:attributes))
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    impuestos_pair = concepto_impuestos_map(c, ns?)

    terceros_pair =
      case c.a_cuenta_terceros do
        nil -> nil
        t -> {key_for("ACuentaTerceros", ns?), ACuentaTerceros.to_map(t, ns: ns?, wrap: false)}
      end

    aduana_pair =
      case c.informacion_aduanera do
        nil ->
          nil

        [] ->
          nil

        list ->
          items = Enum.map(list, &InformacionAduanera.to_map(&1, ns: ns?, wrap: false))
          {key_for("InformacionAduanera", ns?), items}
      end

    predial_pair =
      case c.cuenta_predial do
        nil -> nil
        cp -> {key_for("CuentaPredial", ns?), CuentaPredial.to_map(cp, ns: ns?, wrap: false)}
      end

    complemento_pair =
      case c.complemento do
        nil -> nil
        cc -> {key_for("ComplementoConcepto", ns?), Complemento.to_map(cc, ns: ns?, wrap: false)}
      end

    parte_pair =
      case c.parte do
        nil ->
          nil

        [] ->
          nil

        list ->
          items = Enum.map(list, &Parte.to_map(&1, ns: ns?, wrap: false))
          {key_for("Parte", ns?), items}
      end

    children =
      [
        impuestos_pair,
        terceros_pair,
        aduana_pair,
        predial_pair,
        complemento_pair,
        parte_pair
      ]
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    body = Map.merge(attrs, children)

    if wrap? do
      %{key_for("Concepto", ns?) => body}
    else
      body
    end
  end

  @doc """
  Serializa un `%Cfdi.Concepto{}` a una tupla `XmlBuilder`, incluyendo —
  cuando aplica — `cfdi:Impuestos`, `cfdi:ACuentaTerceros`,
  `cfdi:InformacionAduanera`, `cfdi:CuentaPredial`, `cfdi:ComplementoConcepto`
  y `cfdi:Parte` en el orden que exige el Anexo 20.
  """
  def to_element(nil), do: nil

  def to_element(c) when is_struct(c, __MODULE__) do
    kids =
      [
        impuestos_element(c),
        terceros_element(c)
      ] ++
        aduana_elements(c) ++
        [
          predial_element(c),
          complemento_element(c)
        ] ++
        parte_elements(c)

    kids = Enum.reject(kids, &is_nil/1)

    XmlBuilder.element(
      {"cfdi:Concepto", Cfdi.Xml.Element.__build_attrs__(c, __MODULE__), kids}
    )
  end

  @doc """
  Construye un bloque `<cfdi:Conceptos>` con una lista de `Cfdi.Concepto`.
  """
  def conceptos_block([]), do: nil

  def conceptos_block(conceptos) when is_list(conceptos) do
    kids = Enum.map(conceptos, &to_element/1)
    XmlBuilder.element({"cfdi:Conceptos", %{}, kids})
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp impuestos_element(c) when is_struct(c, __MODULE__) do
    t = c.traslados || []
    r = c.retenciones || []

    cond do
      t == [] and r == [] ->
        nil

      true ->
        kids =
          [
            traslados_block(t),
            retenciones_block(r)
          ]
          |> Enum.reject(&is_nil/1)

        XmlBuilder.element({"cfdi:Impuestos", %{}, kids})
    end
  end

  defp traslados_block([]), do: nil

  defp traslados_block(list) when is_list(list) do
    kids = Enum.map(list, &Cfdi.Traslado.to_element/1)
    XmlBuilder.element({"cfdi:Traslados", %{}, kids})
  end

  defp retenciones_block([]), do: nil

  defp retenciones_block(list) when is_list(list) do
    kids = Enum.map(list, &Cfdi.Retencion.to_element/1)
    XmlBuilder.element({"cfdi:Retenciones", %{}, kids})
  end

  defp terceros_element(c) when is_struct(c, __MODULE__) do
    case c.a_cuenta_terceros do
      nil -> nil
      t -> ACuentaTerceros.to_element(t)
    end
  end

  defp aduana_elements(c) when is_struct(c, __MODULE__) do
    case c.informacion_aduanera do
      nil -> []
      [] -> []
      list when is_list(list) -> Enum.map(list, &InformacionAduanera.to_element/1)
    end
  end

  defp predial_element(c) when is_struct(c, __MODULE__) do
    case c.cuenta_predial do
      nil -> nil
      cp -> CuentaPredial.to_element(cp)
    end
  end

  defp complemento_element(c) when is_struct(c, __MODULE__) do
    case c.complemento do
      nil -> nil
      cc -> Complemento.to_element(cc)
    end
  end

  defp parte_elements(c) when is_struct(c, __MODULE__) do
    case c.parte do
      nil -> []
      [] -> []
      list when is_list(list) -> Enum.map(list, &Parte.to_element/1)
    end
  end

  defp key_for(name, true), do: "cfdi:" <> name
  defp key_for(name, false), do: name

  defp concepto_impuestos_map(c, ns?) do
    traslados = c.traslados || []
    retenciones = c.retenciones || []

    cond do
      traslados == [] and retenciones == [] ->
        nil

      true ->
        inner =
          %{}
          |> maybe_put_traslados(traslados, ns?)
          |> maybe_put_retenciones(retenciones, ns?)

        {key_for("Impuestos", ns?), inner}
    end
  end

  defp maybe_put_traslados(map, [], _ns?), do: map

  defp maybe_put_traslados(map, list, ns?) do
    items = Enum.map(list, &Cfdi.Traslado.to_map(&1, ns: ns?, wrap: false))
    Map.put(map, key_for("Traslados", ns?), %{key_for("Traslado", ns?) => items})
  end

  defp maybe_put_retenciones(map, [], _ns?), do: map

  defp maybe_put_retenciones(map, list, ns?) do
    items = Enum.map(list, &Cfdi.Retencion.to_map(&1, ns: ns?, wrap: false))
    Map.put(map, key_for("Retenciones", ns?), %{key_for("Retencion", ns?) => items})
  end
end
