defmodule Cfdi.Transform.XsltParser do
  @moduledoc false

  alias Cfdi.Transform.Types

  @doc """
  Parsea el contenido de una hoja XSLT y construye un registro de plantillas.
  """
  @spec parse(String.t()) :: {:ok, Types.template_registry()} | {:error, term()}
  def parse(xslt_content) when is_binary(xslt_content) do
    case Saxy.SimpleForm.parse_string(xslt_content) do
      {:ok, form} -> {:ok, walk_stylesheet(form)}
      {:error, _} = e -> e
    end
  end

  defp walk_stylesheet(form) do
    {_root_name, root_attrs, children} = normalize_element(form)
    ns = collect_namespaces(root_attrs, %{})

    templates =
      children
      |> List.wrap()
      |> Enum.filter(&match?({_, _, _}, &1))
      |> Enum.reduce(%{}, fn child, acc ->
        {name, _, _} = el = normalize_element(child)

        if local_name(name) == "template" do
          case parse_template(el) do
            {:ok, %{match: m} = tmpl} -> Map.put(acc, m, tmpl)
            _ -> acc
          end
        else
          acc
        end
      end)

    %{templates: templates, namespaces: ns}
  end

  defp collect_namespaces(attrs, acc) do
    Enum.reduce(attrs, acc, fn
      {"xmlns:" <> prefix, uri}, a -> Map.put(a, prefix, uri)
      {"xmlns", uri}, a -> Map.put(a, "", uri)
      _, a -> a
    end)
  end

  @doc """
  Interpreta un elemento `xsl:template`.
  """
  @spec parse_template(term()) :: {:ok, Types.parsed_template()} | {:error, term()}
  def parse_template(element) do
    {_name, attrs, children} = normalize_element(element)

    match =
      case List.keyfind(attrs, "match", 0) do
        {_, m} -> m
        nil -> "/"
      end

    rules =
      children
      |> List.wrap()
      |> Enum.filter(&match?({_, _, _}, &1))
      |> Enum.map(&parse_rule/1)
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, r} -> r end)

    {:ok, %{match: String.trim(match), rules: rules}}
  end

  @doc """
  Determina si la regla es de atributo, texto (`xsl:value-of`) o hijo (`xsl:apply-templates`, etc.).
  """
  @spec parse_rule(term()) :: {:ok, Types.rule()} | {:error, term()} | :skip
  def parse_rule(element) do
    {name, attrs, _children} = normalize_element(element)
    ln = local_name(name)

    cond do
      ln == "attribute" ->
        case List.keyfind(attrs, "name", 0) do
          {_, n} ->
            req = List.keyfind(attrs, "use", 0) == {"use", "required"}
            {:ok, %{type: :attr, name: n, required: req}}

          nil ->
            {:error, :missing_attribute_name}
        end

      ln == "value-of" ->
        case List.keyfind(attrs, "select", 0) do
          {_, sel} ->
            {:ok,
             %{
               type: :child,
               select: sel,
               for_each: false,
               inline: [],
               apply_templates: false,
               descendant: false
             }}

          nil ->
            {:error, :missing_value_of_select}
        end

      ln == "apply-templates" ->
        case List.keyfind(attrs, "select", 0) do
          {_, sel} ->
            {:ok,
             %{
               type: :child,
               select: sel,
               for_each: false,
               inline: [],
               apply_templates: true,
               descendant: false
             }}

          nil ->
            {:error, :missing_apply_templates_select}
        end

      ln == "for-each" ->
        case List.keyfind(attrs, "select", 0) do
          {_, sel} ->
            {:ok,
             %{
               type: :child,
               select: sel,
               for_each: true,
               inline: [],
               apply_templates: false,
               descendant: false
             }}

          nil ->
            {:error, :missing_for_each_select}
        end

      true ->
        :skip
    end
  end

  defp normalize_element({n, a, c}), do: {to_string(n), a || [], c || []}
  defp normalize_element(other), do: {"#text", [], [other]}

  defp local_name(tag) do
    tag = to_string(tag)

    case String.split(tag, ":", parts: 2) do
      [_p, l] -> l
      [l] -> l
    end
  end

end
