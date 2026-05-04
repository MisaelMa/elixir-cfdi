defmodule SaxonHe.CliShare do
  @moduledoc """
  Flags compartidos entre `saxon-he transform` y `saxon-he query`. Espejo de
  [`cli-share.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/clir/saxon-he/src/cli-share.ts).

  Se inyectan vía `use SaxonHe.CliShare` en `SaxonHe.Transform` y
  `SaxonHe.Query`. Cada función agrega un flag al campo `:args` del struct
  y devuelve el struct para encadenar (`fluent interface`).

      SaxonHe.Transform.new()
      |> SaxonHe.Transform.s("in.xml")
      |> SaxonHe.Transform.xsl("t.xsl")
      |> SaxonHe.Transform.o("out.xml")
      |> SaxonHe.Transform.run()
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      @doc "Append `-catalog:filenames`."
      def catalog(t, filenames), do: SaxonHe.CliShare.append(t, "-catalog:#{filenames}")

      @doc "Append `-dtd:on|off|recover`."
      def dtd(t, opt) when opt in ["on", "off", "recover"],
        do: SaxonHe.CliShare.append(t, "-dtd:#{opt}")

      @doc "Append `-expand:on|off`."
      def expand(t, opt) when opt in ["on", "off"],
        do: SaxonHe.CliShare.append(t, "-expand:#{opt}")

      @doc "Append `-ext:on|off`."
      def ext(t, opt) when opt in ["on", "off"],
        do: SaxonHe.CliShare.append(t, "-ext:#{opt}")

      @doc "Append `-init:initializer`."
      def init(t, initializer), do: SaxonHe.CliShare.append(t, "-init:#{initializer}")

      @doc "Append `-l:on|off` (line numbers)."
      def l(t, opt) when opt in ["on", "off"],
        do: SaxonHe.CliShare.append(t, "-l:#{opt}")

      @doc "Append `-now:format`."
      def now(t, format), do: SaxonHe.CliShare.append(t, "-now:#{format}")

      @doc "Append `-o:filename` (output file)."
      def o(t, filename), do: SaxonHe.CliShare.append(t, "-o:#{filename}")

      @doc "Alias de `o/2` con nombre más descriptivo (no parte del CLI de Saxon)."
      def output(t, filename), do: o(t, filename)

      @doc "Append `-opt:-flags` (optimization flags)."
      def opt(t, flags) when flags in ~w(c d e f g j k l m n r s t v w x),
        do: SaxonHe.CliShare.append(t, "-opt:-#{flags}")

      @doc "Append `-outval:recover|fatal`."
      def outval(t, opt) when opt in ["recover", "fatal"],
        do: SaxonHe.CliShare.append(t, "-outval:#{opt}")

      @doc "Append `-p:on|off`."
      def p(t, opt) when opt in ["on", "off"],
        do: SaxonHe.CliShare.append(t, "-p:#{opt}")

      @doc "Append `-quit:on|off`."
      def quit(t, opt) when opt in ["on", "off"],
        do: SaxonHe.CliShare.append(t, "-quit:#{opt}")

      @doc "Append `-r:classname` (URI resolver)."
      def r(t, classname), do: SaxonHe.CliShare.append(t, "-r:#{classname}")

      @doc "Append `-repeat:N`."
      def repeat(t, n) when is_integer(n), do: SaxonHe.CliShare.append(t, "-repeat:#{n}")

      @doc "Append `-s:filename` (source XML). Lanza si el archivo no existe."
      def s(t, filename) do
        unless File.exists?(filename) do
          raise ArgumentError, "No se puede encontrar el xml a procesar. => #{filename}"
        end

        SaxonHe.CliShare.append(t, "-s:#{filename}")
      end

      @doc "Alias de `s/2` (no parte del CLI de Saxon)."
      def source(t, filename), do: s(t, filename)

      @doc "Append `-sa` (schema-aware)."
      def sa(t), do: SaxonHe.CliShare.append(t, "-sa")

      @doc "Append `-scmin:filename` (schema component model file)."
      def scmin(t, filename), do: SaxonHe.CliShare.append(t, "-scmin:#{filename}")

      @doc "Append `-strip:all|none|ignorable`."
      def strip(t, opt) when opt in ["all", "none", "ignorable"],
        do: SaxonHe.CliShare.append(t, "-strip:#{opt}")

      @doc "Append `-t` (timing/version info)."
      def t(t), do: SaxonHe.CliShare.append(t, "-t")

      @doc "Append `-T:classname` (TraceListener)."
      def t_listener(t, classname), do: SaxonHe.CliShare.append(t, "-T:#{classname}")

      @doc "Append `-TB:filename`."
      def tb(t, filename), do: SaxonHe.CliShare.append(t, "-TB:#{filename}")

      @doc "Append `-TJ` (trace external Java method calls)."
      def tj(t), do: SaxonHe.CliShare.append(t, "-TJ")

      @doc "Append `-Tlevel:none|low|normal|high`."
      def t_level(t, level) when level in ["none", "low", "normal", "high"],
        do: SaxonHe.CliShare.append(t, "-Tlevel:#{level}")

      @doc "Append `-Tout:filename`."
      def t_out(t, filename), do: SaxonHe.CliShare.append(t, "-Tout:#{filename}")

      @doc "Append `-TP:filename` (profiling output)."
      def tp(t, filename), do: SaxonHe.CliShare.append(t, "-TP:#{filename}")

      @doc "Append `-traceout:filename`."
      def traceout(t, filename), do: SaxonHe.CliShare.append(t, "-traceout:#{filename}")

      @doc "Append `-tree:linked|tiny|tinyc`."
      def tree(t, level) when level in ["linked", "tiny", "tinyc"],
        do: SaxonHe.CliShare.append(t, "-tree:#{level}")

      @doc "Append `-u` (treat source as URI)."
      def u(t), do: SaxonHe.CliShare.append(t, "-u")

      @doc "Append `-val:strict|lax`."
      def val(t, opt) when opt in ["strict", "lax"],
        do: SaxonHe.CliShare.append(t, "-val:#{opt}")

      @doc "Append `-x:classname` (SAX parser for source)."
      def x(t, classname), do: SaxonHe.CliShare.append(t, "-x:#{classname}")

      @doc "Append `-xi:on|off` (XInclude)."
      def xi(t, opt) when opt in ["on", "off"],
        do: SaxonHe.CliShare.append(t, "-xi:#{opt}")

      @doc "Append `-xmlversion:1.0|1.1`."
      def xmlversion(t, opt) when opt in ["1.0", "1.1"],
        do: SaxonHe.CliShare.append(t, "-xmlversion:#{opt}")

      @doc "Append `-xsd:file`."
      def xsd(t, file), do: SaxonHe.CliShare.append(t, "-xsd:#{file}")

      @doc "Append `-xsdversion:1.0|1.1`."
      def xsdversion(t, opt) when opt in ["1.0", "1.1"],
        do: SaxonHe.CliShare.append(t, "-xsdversion:#{opt}")

      @doc "Append `-xsiloc:on|off`."
      def xsiloc(t, opt) when opt in ["on", "off"],
        do: SaxonHe.CliShare.append(t, "-xsiloc:#{opt}")

      @doc "Append `--feature:value`."
      def feature(t, value), do: SaxonHe.CliShare.append(t, "--feature:#{value}")
    end
  end

  @doc """
  Concatena un flag al final del campo `:args` del struct y lo devuelve.
  Pensado para uso interno desde el macro `__using__`.
  """
  @spec append(struct(), String.t()) :: struct()
  def append(%_{args: args} = t, flag) when is_binary(flag) do
    %{t | args: args ++ [flag]}
  end
end
