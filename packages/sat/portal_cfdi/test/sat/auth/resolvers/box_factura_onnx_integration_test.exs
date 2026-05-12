defmodule Sat.PortalCfdi.Auth.Resolvers.BoxFacturaOnnxIntegrationTest do
  @moduledoc """
  Test de integracion del resolver BoxFactura ONNX.

  Solo se ejecuta cuando:
    1. Las deps `:ortex`, `:image` y `:nx` estan instaladas en el ambiente.
    2. La variable de entorno `SAT_CAPTCHA_ONNX_MODEL` apunta a un `.onnx`
       valido descargado del repo BoxFactura/sat-captcha-ai-model.
    3. Existe una imagen de captcha en `SAT_CAPTCHA_TEST_IMAGE` para
       probar la inferencia end-to-end (opcional).

  Para correrlo localmente:

      git clone https://github.com/BoxFactura/sat-captcha-ai-model /tmp/box
      cd /tmp/box && python train.py  # genera /tmp/box/models/sat.onnx

      # Agregar a tu mix.exs en deps:
      #   {:ortex, "~> 0.1.10"},
      #   {:image, "~> 0.54"}
      mix deps.get

      SAT_CAPTCHA_ONNX_MODEL=/tmp/box/models/sat.onnx \\
      SAT_CAPTCHA_TEST_IMAGE=/tmp/box/samples/captcha.png \\
      mix test --include onnx_integration test/sat/auth/resolvers/box_factura_onnx_integration_test.exs

  En CI / publicacion, el modelo NO se incluye (ver `package/0` en mix.exs).
  """

  use ExUnit.Case, async: false

  alias Sat.PortalCfdi.Auth.Resolvers.BoxFacturaOnnx

  @moduletag :onnx_integration

  setup do
    model_path = System.get_env("SAT_CAPTCHA_ONNX_MODEL")
    image_path = System.get_env("SAT_CAPTCHA_TEST_IMAGE")

    cond do
      is_nil(model_path) ->
        {:ok, skip: :no_model_env}

      not File.exists?(model_path) ->
        {:ok, skip: {:model_missing, model_path}}

      not Code.ensure_loaded?(Ortex) ->
        {:ok, skip: :ortex_not_installed}

      true ->
        {:ok, %{model_path: model_path, image_path: image_path}}
    end
  end

  test "resolve/2 retorna texto con un modelo y captcha reales", ctx do
    cond do
      ctx[:skip] ->
        IO.warn("test skipped: #{inspect(ctx[:skip])}")
        :ok

      is_nil(ctx[:image_path]) ->
        IO.warn("set SAT_CAPTCHA_TEST_IMAGE para correr inferencia end-to-end")
        :ok

      true ->
        image = File.read!(ctx.image_path)
        assert {:ok, text} = BoxFacturaOnnx.resolve(image, model_path: ctx.model_path)
        assert is_binary(text)
        assert String.length(text) >= 4
        assert String.length(text) <= 8
        assert text =~ ~r/^[A-Z0-9]+$/
    end
  end

  test "resolve/2 sin :ortex retorna :dependency_missing claro" do
    if Code.ensure_loaded?(Ortex) do
      :ok
    else
      assert {:error, {:dependency_missing, _mods, _hint}} =
               BoxFacturaOnnx.resolve(<<1, 2, 3>>, model_path: "/tmp/fake.onnx")
    end
  end
end
