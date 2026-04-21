defmodule Cfdi.Transform.CadenaEngine do
  @moduledoc false

  alias Cfdi.Transform.Types

  @spec normalize_space(String.t() | nil) :: String.t()
  def normalize_space(nil), do: ""

  def normalize_space(string) when is_binary(string) do
    string
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  @spec requerido(term()) :: String.t()
  def requerido(value), do: "|" <> normalize_space(to_string(value))

  @spec opcional(term() | nil) :: String.t()
  def opcional(nil), do: ""
  def opcional(value), do: "|" <> normalize_space(to_string(value))

  @doc """
  Genera la cadena original aplicando las plantillas del registro al XML del comprobante.
  """
  @spec generate_cadena_original(String.t(), Types.template_registry()) ::
          {:ok, String.t()} | {:error, term()}
  def generate_cadena_original(xml_content, registry) when is_binary(xml_content) do
    case Saxy.SimpleForm.parse_string(xml_content) do
      {:ok, doc} ->
        node = normalize_element(doc)
        parts = process_node(node, registry)
        {:ok, IO.iodata_to_binary(parts)}

      {:error, _} = e ->
        e
    end
  end

  @doc """
  Procesa un nodo contra la plantilla que corresponda a su `match`.
  """
  @spec process_node(term(), Types.template_registry()) :: iodata
  def process_node(node, registry) do
    case find_template(node, registry.templates) do
      nil -> []
      %{rules: rules} -> apply_rules(node, rules, registry)
    end
  end

  defp find_template({tag, _, _}, templates) do
    t = to_string(tag)
    Map.get(templates, t) || Map.get(templates, local_name(t)) || Map.get(templates, "/")
  end

  defp apply_rules(node, rules, registry) do
    Enum.map(rules, fn rule -> apply_rule(node, rule, registry) end)
  end

  defp apply_rule(node, %{type: :attr, name: name, required: true}, _registry) do
    {_t, attrs, _} = normalize_element(node)
    v = attr_val(attrs, name)
    requerido(v || "")
  end

  defp apply_rule(node, %{type: :attr, name: name, required: false}, _registry) do
    {_t, attrs, _} = normalize_element(node)
    opcional(attr_val(attrs, name))
  end

  defp apply_rule(node, %{type: :child, apply_templates: true} = r, registry) do
    targets = resolve_select_all(node, r.select)

    Enum.map(targets, fn n -> process_node(n, registry) end)
  end

  defp apply_rule(node, %{type: :child, for_each: true} = r, registry) do
    targets = resolve_select_all(node, r.select)

    Enum.map(targets, fn n -> process_node(n, registry) end)
  end

  defp apply_rule(node, %{type: :child, apply_templates: false} = r, _registry) do
    case resolve_select(node, r.select) do
      nil -> ""
      val when is_binary(val) -> requerido(val)
      n -> requerido(text_content(n))
    end
  end

  defp normalize_element({n, a, c}), do: {to_string(n), a || [], c || []}

  defp local_name(tag) do
    t = to_string(tag)

    case String.split(t, ":", parts: 2) do
      [_p, l] -> l
      [l] -> l
    end
  end

  defp attr_val(attrs, name) do
    case List.keyfind(attrs, name, 0) do
      {_, v} -> v
      nil -> nil
    end
  end

  @doc """
  Navega el árbol XML a partir del nodo actual según una expresión `select` sencilla
  (`@atributo`, `hijo`, `prefijo:hijo` o rutas con `/`).
  """
  @spec resolve_select(term(), String.t()) :: term() | nil
  def resolve_select(node, select) when is_binary(select) do
    select = String.trim(select)

    cond do
      String.starts_with?(select, "@") ->
        {_t, attrs, _} = normalize_element(node)
        attr_val(attrs, String.trim_leading(select, "@"))

      select == "." ->
        text_content(node)

      String.contains?(select, "/") ->
        [h | rest] = String.split(select, "/", trim: true)
        first = resolve_child(node, h)

        case rest do
          [] -> first
          _ -> Enum.reduce(rest, first, fn step, acc -> acc && resolve_child(acc, step) end)
        end

      true ->
        resolve_child(node, select)
    end
  end

  defp resolve_child({_t, _a, children} = node, step) do
    step_ln = local_name(step)

    children
    |> List.wrap()
    |> Enum.find_value(fn
      {tag, _, _} = child ->
        if local_name(to_string(tag)) == step_ln or to_string(tag) == step do
          child
        else
          false
        end

      _ ->
        false
    end) || resolve_descendant(node, step)
  end

  defp resolve_descendant({_t, _a, children}, step) do
    step_ln = local_name(step)

    children
    |> List.wrap()
    |> Enum.find_value(fn
      {tag, _, _} = child ->
        cond do
          local_name(to_string(tag)) == step_ln or to_string(tag) == step ->
            child

          true ->
            resolve_descendant(child, step)
        end

      _ ->
        false
    end)
  end

  defp resolve_select_all(node, select) do
    select = String.trim(select)

    if String.contains?(select, "/") do
      [h | rest] = String.split(select, "/", trim: true)
      first = resolve_child(node, h)

      case {first, rest} do
        {nil, _} ->
          []

        {n, []} ->
          [n]

        {n, steps} ->
          Enum.reduce(steps, [n], fn step, acc ->
            Enum.flat_map(acc, fn x -> list_children_matching(x, step) end)
          end)
      end
    else
      list_children_matching(node, select)
    end
  end

  defp list_children_matching({_t, _a, children}, step) do
    step_ln = local_name(step)

    children
    |> List.wrap()
    |> Enum.filter(fn
      {tag, _, _} ->
        local_name(to_string(tag)) == step_ln or to_string(tag) == step

      _ ->
        false
    end)
  end

  defp text_content({_t, _a, children}) do
    children
    |> List.wrap()
    |> Enum.map(fn
      s when is_binary(s) -> s
      _ -> ""
    end)
    |> IO.iodata_to_binary()
    |> normalize_space()
  end
end
