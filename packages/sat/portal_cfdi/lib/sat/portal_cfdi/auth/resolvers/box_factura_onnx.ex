defmodule Sat.PortalCfdi.Auth.Resolvers.BoxFacturaOnnx do
  @moduledoc """
  Resuelve captchas del SAT usando el modelo ONNX de
  https://github.com/BoxFactura/sat-captcha-ai-model.

  Caracteristicas del modelo:
    * Entrada: tensor `float32` shape `[1, 60, 160, 3]` (PNG/JPG 160x60 RGB)
    * Salida: logits por posicion → softmax → argmax sobre el alfabeto
      `"Y65WRD98SMBG3NJ21CP4KF7ZXHVTQL"` (30 chars)
    * Postprocesamiento: deduplicar caracteres consecutivos repetidos.

  ## Dependencias requeridas en el proyecto del consumidor

  Este resolver NO declara las deps en el `mix.exs` de `sat_portal_cfdi` para
  no obligar a instalar onnxruntime + Rust toolchain a quienes solo usen
  Console / 2captcha / etc. Si vas a usarlo, agrega a TU proyecto:

      def deps do
        [
          {:sat_portal_cfdi, "..."},
          {:ortex, "~> 0.1.10"},   # ONNX Runtime bindings
          {:image, "~> 0.54"}      # Procesamiento de imagenes
        ]
      end

  Si no estan instaladas, `resolve/2` retorna
  `{:error, {:dependency_missing, ...}}` con instrucciones claras.

  ## Modelo

  El modelo `.onnx` no se distribuye con la libreria (es ~6 MB binario).
  Bajalo del repo de BoxFactura:

      git clone https://github.com/BoxFactura/sat-captcha-ai-model
      # copia el archivo .onnx generado a tu app y pasa la ruta

  ## Opciones

    * `:model_path` (requerido) — ruta al `.onnx`
    * `:alphabet` — default `"Y65WRD98SMBG3NJ21CP4KF7ZXHVTQL"`
    * `:input_height` — default 60
    * `:input_width` — default 160
  """

  @behaviour Sat.PortalCfdi.Auth.CaptchaResolver

  @default_alphabet "Y65WRD98SMBG3NJ21CP4KF7ZXHVTQL"
  @default_height 60
  @default_width 160

  @impl true
  def resolve(image) when is_binary(image), do: {:error, :model_path_required}

  @impl true
  def resolve(image, opts) when is_binary(image) and is_list(opts) do
    with {:ok, model_path} <- fetch_model_path(opts),
         :ok <- ensure_deps(),
         {:ok, model} <- load_model(model_path),
         {:ok, tensor} <- preprocess(image, opts),
         {:ok, logits} <- predict(model, tensor),
         {:ok, text} <- postprocess(logits, opts) do
      {:ok, text}
    end
  end

  defp ensure_deps do
    missing =
      [Ortex, Image, Nx]
      |> Enum.reject(&Code.ensure_loaded?/1)

    case missing do
      [] -> :ok
      mods -> {:error, {:dependency_missing, mods, "agrega :ortex, :image y :nx a tu mix.exs"}}
    end
  end

  defp fetch_model_path(opts) do
    case Keyword.get(opts, :model_path) do
      nil ->
        {:error, :model_path_required}

      path when is_binary(path) ->
        if File.exists?(path), do: {:ok, path}, else: {:error, {:model_not_found, path}}
    end
  end

  defp load_model(path) do
    {:ok, apply(Ortex, :load, [path])}
  rescue
    e -> {:error, {:ortex_load_failed, e}}
  end

  # PNG/JPG -> tensor float32 [1, height, width, 3] normalizado a 0..1
  defp preprocess(image_bytes, opts) do
    height = Keyword.get(opts, :input_height, @default_height)
    width = Keyword.get(opts, :input_width, @default_width)

    with {:ok, img} <- image_from_binary(image_bytes),
         {:ok, resized} <- image_thumbnail(img, width, height) do
      tensor = image_to_tensor(resized, height, width)
      {:ok, tensor}
    end
  rescue
    e -> {:error, {:preprocess_failed, e}}
  end

  defp image_from_binary(bytes) do
    case apply(Image, :from_binary, [bytes]) do
      {:ok, _} = ok -> ok
      {:error, _} = err -> err
      other -> {:error, {:image_from_binary_unexpected, other}}
    end
  end

  defp image_thumbnail(img, width, height) do
    # Image.thumbnail acepta string "WIDTHxHEIGHT" + opts.
    case apply(Image, :thumbnail, [img, "#{width}x#{height}", [resize: :force]]) do
      {:ok, _} = ok -> ok
      {:error, _} = err -> err
      other -> {:error, {:thumbnail_unexpected, other}}
    end
  end

  defp image_to_tensor(img, height, width) do
    # Image.to_nx convierte a Nx.Tensor con shape {height, width, channels}.
    {:ok, nx_tensor} = apply(Image, :to_nx, [img])

    nx_tensor
    |> apply_nx(:as_type, [:f32])
    |> apply_nx(:divide, [255.0])
    |> apply_nx(:reshape, [{1, height, width, 3}])
  end

  defp apply_nx(tensor, fun, args) do
    apply(Nx, fun, [tensor | args])
  end

  defp predict(model, tensor) do
    {output} = apply(Ortex, :run, [model, {tensor}])
    logits_list = apply(Nx, :to_list, [output])

    case logits_list do
      [batch] when is_list(batch) -> {:ok, batch}
      list when is_list(list) -> {:ok, list}
    end
  rescue
    e -> {:error, {:predict_failed, e}}
  end

  defp postprocess(logits, opts) do
    alphabet = Keyword.get(opts, :alphabet, @default_alphabet)
    text = decode_logits(logits, alphabet)

    if text == "", do: {:error, :empty_decoding}, else: {:ok, text}
  end

  @doc """
  Decoder puro de logits → texto. Aplica argmax por posicion + dedupe de
  caracteres consecutivos repetidos (CTC-style).

  Util para tests sin tener Ortex instalado.
  """
  @spec decode_logits([[number()]], String.t()) :: String.t()
  def decode_logits(logits_per_position, alphabet \\ @default_alphabet) do
    chars = String.graphemes(alphabet)

    logits_per_position
    |> Enum.map(fn position_logits ->
      max_index =
        position_logits
        |> Enum.with_index()
        |> Enum.max_by(fn {v, _i} -> v end)
        |> elem(1)

      Enum.at(chars, max_index)
    end)
    |> dedupe_consecutive()
    |> Enum.join("")
  end

  defp dedupe_consecutive([]), do: []

  defp dedupe_consecutive([first | rest]) do
    {result, _last} =
      Enum.reduce(rest, {[first], first}, fn ch, {acc, last} ->
        if ch == last, do: {acc, last}, else: {acc ++ [ch], ch}
      end)

    result
  end

  @doc "Alfabeto default usado por el modelo BoxFactura."
  def default_alphabet, do: @default_alphabet
end
