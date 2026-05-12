defmodule Sat.PortalCfdi.Internal.FormTest do
  use ExUnit.Case, async: true

  alias Sat.PortalCfdi.Internal.Form

  describe "extract_hidden_inputs/1" do
    test "extrae todos los inputs hidden de un form ASP.NET" do
      html = """
      <form>
        <input type="hidden" name="__VIEWSTATE" value="VIEWSTATE_VALUE_BASE64==" />
        <input type="hidden" name="__EVENTVALIDATION" value="EV_VALIDATION_BASE64" />
        <input type="hidden" name="__VIEWSTATEGENERATOR" value="ABCD1234" />
        <input type="text" name="user" value="should-be-ignored" />
        <input type="hidden" name="empty" value="" />
      </form>
      """

      result = Form.extract_hidden_inputs(html)

      assert result["__VIEWSTATE"] == "VIEWSTATE_VALUE_BASE64=="
      assert result["__EVENTVALIDATION"] == "EV_VALIDATION_BASE64"
      assert result["__VIEWSTATEGENERATOR"] == "ABCD1234"
      assert result["empty"] == ""
      refute Map.has_key?(result, "user")
    end

    test "retorna mapa vacio si no hay inputs" do
      assert Form.extract_hidden_inputs("<html></html>") == %{}
    end
  end

  describe "encode/1" do
    test "URL-encode de un map" do
      result = Form.encode(%{"a" => "1", "b" => "hello world"})
      # Order is map iteration; check both possible orderings
      assert result == "a=1&b=hello+world" or result == "b=hello+world&a=1"
    end

    test "encodea caracteres especiales" do
      result = Form.encode(%{"key" => "valor con & ampersand"})
      assert result =~ "valor+con+%26+ampersand"
    end
  end
end
