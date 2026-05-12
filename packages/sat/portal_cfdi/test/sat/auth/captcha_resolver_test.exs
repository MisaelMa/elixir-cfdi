defmodule Sat.PortalCfdi.Auth.CaptchaResolverTest do
  use ExUnit.Case, async: true

  alias Sat.PortalCfdi.Auth.CaptchaResolver
  alias Sat.PortalCfdi.Auth.Resolvers.{BoxFacturaOnnx, Mock, Multi}

  describe "dispatch/2 con funcion" do
    test "llama la funcion arity 1" do
      resolver = fn _img -> {:ok, "FN_ANSWER"} end
      assert {:ok, "FN_ANSWER"} = CaptchaResolver.dispatch(<<>>, resolver)
    end

    test "propaga errores de la funcion" do
      resolver = fn _img -> {:error, :fn_failed} end
      assert {:error, :fn_failed} = CaptchaResolver.dispatch(<<>>, resolver)
    end
  end

  describe "dispatch/2 con modulo" do
    test "llama Modulo.resolve/1" do
      assert {:ok, "MOCK_DEFAULT"} = CaptchaResolver.dispatch(<<>>, Mock)
    end
  end

  describe "dispatch/2 con {modulo, opts}" do
    test "llama Modulo.resolve/2 con las opciones" do
      assert {:ok, "ABC"} = CaptchaResolver.dispatch(<<>>, {Mock, answer: "ABC"})
    end

    test "Mock con error retorna error" do
      assert {:error, :forced_error} = CaptchaResolver.dispatch(<<>>, {Mock, error: :forced_error})
    end
  end

  describe "dispatch/2 con resolver invalido" do
    test "retorna error claro" do
      assert {:error, {:invalid_resolver, _, _}} = CaptchaResolver.dispatch(<<>>, 123)
    end
  end

  describe "Multi resolver con fallback" do
    test "primer resolver fallido, segundo OK" do
      first = {Mock, error: :no_match}
      second = {Mock, answer: "FALLBACK_OK"}

      assert {:ok, "FALLBACK_OK"} =
               CaptchaResolver.dispatch(<<>>, {Multi, resolvers: [first, second]})
    end

    test "todos fallan, retorna lista de errores" do
      a = {Mock, error: :a_failed}
      b = {Mock, error: :b_failed}

      assert {:error, {:multi_failed, errors}} =
               CaptchaResolver.dispatch(<<>>, {Multi, resolvers: [a, b]})

      assert length(errors) == 2
    end

    test "sin resolvers en la lista" do
      assert {:error, {:multi_failed, []}} = CaptchaResolver.dispatch(<<>>, {Multi, resolvers: []})
    end
  end

  describe "BoxFacturaOnnx.decode_logits/2" do
    test "decodifica logits + dedupe de caracteres consecutivos" do
      # Modelo BoxFactura: alfabeto "Y65WRD98SMBG3NJ21CP4KF7ZXHVTQL" (30 chars)
      alphabet = BoxFacturaOnnx.default_alphabet()
      n = byte_size(alphabet)
      assert n == 30

      # Logits: vector de N numeros, el "ganador" tiene valor alto
      def_logits = fn winner ->
        for i <- 0..(n - 1) do
          if i == winner, do: 10.0, else: 0.0
        end
      end

      logits = [
        def_logits.(0),  # Y
        def_logits.(1),  # 6
        def_logits.(2),  # 5
        def_logits.(0)   # Y
      ]

      result = BoxFacturaOnnx.decode_logits(logits, alphabet)
      assert result == "Y65Y"
    end

    test "deduplica caracteres consecutivos repetidos" do
      alphabet = "ABC"
      def_logits = fn winner ->
        for i <- 0..2 do
          if i == winner, do: 10.0, else: 0.0
        end
      end

      # AABBCA -> ABCA
      logits = [
        def_logits.(0),  # A
        def_logits.(0),  # A (consecutivo, se dedupe)
        def_logits.(1),  # B
        def_logits.(1),  # B (consecutivo, se dedupe)
        def_logits.(2),  # C
        def_logits.(0)   # A
      ]

      assert BoxFacturaOnnx.decode_logits(logits, alphabet) == "ABCA"
    end
  end

  describe "BoxFacturaOnnx.resolve/2" do
    test "sin model_path retorna error" do
      assert {:error, :model_path_required} = BoxFacturaOnnx.resolve(<<1, 2, 3>>, [])
    end

    test "model_path inexistente retorna error" do
      assert {:error, {:model_not_found, _}} =
               BoxFacturaOnnx.resolve(<<1, 2, 3>>, model_path: "/no/such/file.onnx")
    end
  end

  describe "Resolvers.Mock" do
    test "queue retorna el primer elemento" do
      assert {:ok, "FIRST"} = Mock.resolve(<<>>, queue: ["FIRST", "SECOND"])
    end

    test "queue vacio retorna error" do
      assert {:error, :empty_queue} = Mock.resolve(<<>>, queue: [])
    end
  end
end
