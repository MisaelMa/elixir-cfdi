defmodule Cfdi.Xml.Element do
  @moduledoc """
  Declarative XML element schema — Ecto-style DSL for CFDI elements.

  Define an element's attributes, namespaces, and XML tag in one module.
  The macro generates:

    * `defstruct` with all declared fields (default `nil`)
    * `@type t` with attribute types
    * `to_element/1` (and `to_element/2` for elements that accept children)
      that serializes to an `XmlBuilder` tuple
    * `__xml__/1` introspection helpers (`:tag`, `:attributes`, `:children`,
      `:namespaces`)

  ## Example

      defmodule Cfdi.Emisor do
        use Cfdi.Xml.Element, tag: "cfdi:Emisor"

        attribute :Rfc, :string
        attribute :Nombre, :string
        attribute :RegimenFiscal, :string
        attribute :FacAtrAdquirente, :string
      end

  Now you can do:

      %Cfdi.Emisor{Rfc: "AAA010101AAA", Nombre: "ACME"}
      |> Cfdi.Emisor.to_element()
      #=> {"cfdi:Emisor", %{"Rfc" => "AAA010101AAA", "Nombre" => "ACME"}, nil}

  ## Namespaces (root element)

      defmodule Cfdi.Comprobante do
        use Cfdi.Xml.Element, tag: "cfdi:Comprobante", accepts_children: true

        xmlns :cfdi, "http://www.sat.gob.mx/cfd/4"
        xmlns :xsi, "http://www.w3.org/2001/XMLSchema-instance"

        attribute :Version, :string
        # ...
      end

  When `accepts_children: true` is set, `to_element/2` is defined with a
  second argument for nested XML tuples.

  ## Children fields (not serialized as attributes)

  Some CFDI elements have fields that represent nested structures rather
  than XML attributes (e.g. `Concepto` holds a list of `impuestos`). Use
  `child` instead of `attribute`:

      defmodule Cfdi.Concepto do
        use Cfdi.Xml.Element, tag: "cfdi:Concepto"

        attribute :ClaveProdServ, :string
        # ...
        child :impuestos, :list
        child :informacion_aduanera, :list
      end

  Children appear in the struct and `@type t` but are not serialized to
  XML attributes in the auto-generated `to_element/1` — callers render
  them explicitly.
  """

  @doc false
  defmacro __using__(opts) do
    tag = Keyword.fetch!(opts, :tag)
    accepts_children = Keyword.get(opts, :accepts_children, false)

    quote do
      import Cfdi.Xml.Element, only: [attribute: 2, attribute: 3, child: 2, xmlns: 2]

      Module.register_attribute(__MODULE__, :xml_attributes, accumulate: true)
      Module.register_attribute(__MODULE__, :xml_children, accumulate: true)
      Module.register_attribute(__MODULE__, :xml_namespaces, accumulate: true)

      @xml_tag unquote(tag)
      @xml_accepts_children unquote(accepts_children)

      @before_compile Cfdi.Xml.Element
    end
  end

  @doc """
  Declares an XML attribute on the element.
  """
  defmacro attribute(name, type, _opts \\ []) do
    quote do
      @xml_attributes {unquote(name), unquote(type)}
    end
  end

  @doc """
  Declares a nested-structure field that is NOT serialized as an attribute.
  """
  defmacro child(name, type) do
    quote do
      @xml_children {unquote(name), unquote(type)}
    end
  end

  @doc """
  Declares a namespace (xmlns:prefix="uri") for the element. Typically used
  on root elements only.
  """
  defmacro xmlns(prefix, uri) do
    quote do
      @xml_namespaces {unquote(prefix), unquote(uri)}
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    attrs = Module.get_attribute(env.module, :xml_attributes) |> Enum.reverse()
    children = Module.get_attribute(env.module, :xml_children) |> Enum.reverse()
    namespaces = Module.get_attribute(env.module, :xml_namespaces) |> Enum.reverse()
    accepts_children = Module.get_attribute(env.module, :xml_accepts_children)

    attr_names = Enum.map(attrs, &elem(&1, 0))
    child_names = Enum.map(children, &elem(&1, 0))
    struct_fields = attr_names ++ child_names

    type_spec =
      (attrs ++ children)
      |> Enum.map(fn {name, type} -> {name, type_to_spec(type)} end)

    to_element_arity =
      if accepts_children do
        quote do
          @spec to_element(t()) :: tuple()
          def to_element(%__MODULE__{} = el), do: to_element(el, [])

          @spec to_element(t(), iodata()) :: tuple()
          def to_element(%__MODULE__{} = el, kids) do
            XmlBuilder.element({@xml_tag, Cfdi.Xml.Element.__build_attrs__(el, __MODULE__), List.wrap(kids)})
          end
        end
      else
        quote do
          @spec to_element(t() | nil) :: tuple() | nil
          def to_element(nil), do: nil

          def to_element(%__MODULE__{} = el) do
            XmlBuilder.element({@xml_tag, Cfdi.Xml.Element.__build_attrs__(el, __MODULE__), nil})
          end
        end
      end

    quote do
      defstruct unquote(struct_fields)

      @type t :: %__MODULE__{unquote_splicing(type_spec)}

      def __xml__(:tag), do: @xml_tag
      def __xml__(:attributes), do: unquote(attr_names)
      def __xml__(:children), do: unquote(child_names)
      def __xml__(:namespaces), do: unquote(Macro.escape(namespaces))
      def __xml__(:accepts_children), do: @xml_accepts_children

      @doc "Tag XML completo (con namespace, si lo hay). Ej: `\"cfdi:Emisor\"`."
      @spec tag() :: String.t()
      def tag(), do: @xml_tag

      @doc "Prefijo de namespace del tag (`\"cfdi\"`) o `nil` si no lleva."
      @spec namespace() :: String.t() | nil
      def namespace(), do: Cfdi.Xml.Element.__split_tag__(@xml_tag) |> elem(0)

      @doc "Nombre local del tag, sin namespace. Ej: `\"Emisor\"`."
      @spec local_name() :: String.t()
      def local_name(), do: Cfdi.Xml.Element.__split_tag__(@xml_tag) |> elem(1)

      @doc """
      Proyecta la struct a mapa.

      Opciones:
        * `:ns` — `true` (default) incluye prefijo y envuelve bajo `"cfdi:Tag"`;
          `false` devuelve solo los atributos como mapa plano.
        * `:wrap` — `true` (default) envuelve bajo la llave del tag; `false`
          devuelve solo el cuerpo.
      """
      @spec to_map(t() | nil) :: map() | nil
      def to_map(nil), do: nil
      def to_map(%__MODULE__{} = el), do: to_map(el, [])

      @spec to_map(t() | nil, keyword()) :: map() | nil
      def to_map(nil, _opts), do: nil

      def to_map(%__MODULE__{} = el, opts) when is_list(opts) do
        Cfdi.Xml.Element.__to_map__(el, __MODULE__, opts)
      end

      unquote(to_element_arity)

      defoverridable tag: 0,
                     namespace: 0,
                     local_name: 0,
                     to_map: 1,
                     to_map: 2,
                     to_element: 1
    end
  end

  @doc false
  def __split_tag__(tag) when is_binary(tag) do
    case String.split(tag, ":", parts: 2) do
      [ns, local] -> {ns, local}
      [local] -> {nil, local}
    end
  end

  @doc false
  # Proyección genérica struct → mapa. Soporta opción `:ns` (incluir prefijo)
  # y `:wrap` (envolver bajo la llave del tag). Se llama desde cada módulo.
  def __to_map__(struct, module, opts) do
    ns? = Keyword.get(opts, :ns, true)
    wrap? = Keyword.get(opts, :wrap, true)

    attr_names = module.__xml__(:attributes)
    child_names = module.__xml__(:children)

    attrs =
      struct
      |> Map.from_struct()
      |> Map.take(attr_names)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    kids =
      struct
      |> Map.from_struct()
      |> Map.take(child_names)
      |> Enum.reject(fn {_, v} -> is_nil(v) or v == [] end)
      |> Map.new(fn {k, v} -> {__stringify_child_key__(k, ns?), __project_child__(v, ns?)} end)

    body = Map.merge(attrs, kids)

    if wrap? do
      %{tag_key(module, ns?) => body}
    else
      body
    end
  end

  @doc false
  def __stringify_child_key__(k, _ns?) when is_binary(k), do: k

  def __stringify_child_key__(k, ns?) when is_atom(k) do
    s = Atom.to_string(k)

    cond do
      not String.contains?(s, ":") -> k
      ns? -> s
      true -> s |> String.split(":", parts: 2) |> List.last()
    end
  end

  @doc false
  def __project_child__(v, ns?) when is_list(v), do: Enum.map(v, &__project_child__(&1, ns?))

  def __project_child__(%mod{} = s, ns?) do
    if function_exported?(mod, :to_map, 2) do
      mod.to_map(s, ns: ns?, wrap: false)
    else
      s |> Map.from_struct() |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()
    end
  end

  def __project_child__(v, _ns?), do: v

  defp tag_key(module, true), do: module.tag()
  defp tag_key(module, false), do: module.local_name()

  @doc false
  # Shared attribute-building logic used by the macro-generated to_element/1.
  # Takes a struct and its module, emits the attribute map for XmlBuilder,
  # including xmlns:* entries when the element has namespaces declared.
  def __build_attrs__(struct, module) do
    attr_names = module.__xml__(:attributes)
    namespaces = module.__xml__(:namespaces)

    base =
      struct
      |> Map.from_struct()
      |> Map.take(attr_names)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {Atom.to_string(k), to_string(v)} end)

    Enum.reduce(namespaces, base, fn {prefix, uri}, acc ->
      Map.put(acc, "xmlns:#{Atom.to_string(prefix)}", uri)
    end)
  end

  # Maps the DSL type atom to an AST for `@type t`.
  defp type_to_spec(:string), do: quote(do: String.t() | nil)
  defp type_to_spec(:integer), do: quote(do: integer() | nil)
  defp type_to_spec(:decimal), do: quote(do: String.t() | Decimal.t() | nil)
  defp type_to_spec(:datetime), do: quote(do: String.t() | DateTime.t() | nil)
  defp type_to_spec(:boolean), do: quote(do: boolean() | nil)
  defp type_to_spec(:list), do: quote(do: list() | nil)
  defp type_to_spec(:map), do: quote(do: map() | nil)
  defp type_to_spec(_other), do: quote(do: term() | nil)
end
