defmodule Sat.PortalCfdi.Internal.ConsultaTest do
  use ExUnit.Case, async: true

  alias Sat.PortalCfdi.Internal.Consulta

  describe "parse_pagination_meta/1" do
    test "extrae 'Pagina X de N'" do
      html = """
      <div class="pager">Página 2 de 7</div>
      <div>Total registros: 145</div>
      """

      {total_cfdis, total_paginas} = Consulta.parse_pagination_meta(html)
      assert total_cfdis == 145
      assert total_paginas == 7
    end

    test "retorna :unknown cuando no hay info" do
      assert Consulta.parse_pagination_meta("<html></html>") == {:unknown, :unknown}
    end
  end

  describe "pagination_has_next?/3" do
    test "true cuando current < total" do
      assert Consulta.pagination_has_next?("", 1, 5) == true
      assert Consulta.pagination_has_next?("", 4, 5) == true
    end

    test "false cuando current == total" do
      assert Consulta.pagination_has_next?("", 5, 5) == false
    end

    test "detecta __doPostBack Page$Next" do
      html = ~s|<a href="javascript:__doPostBack('ctl00$MainContent$Pagination','Page$Next')">Siguiente</a>|
      assert Consulta.pagination_has_next?(html, 1, :unknown) == true
    end
  end

  describe "parse_results/1" do
    test "parsea filas de la tabla de resultados del portal" do
      html = """
      <html><body>
      <table id="ctl00_MainContent_tblResult">
        <tr>
          <td>11111111-1111-1111-1111-111111111111</td>
          <td>AAA010101AAA</td>
          <td>EMISOR S.A.</td>
          <td>BBB010101BBB</td>
          <td>RECEPTOR S.A.</td>
          <td>2025-01-15T10:00:00</td>
          <td>2025-01-15T10:00:05</td>
          <td>$1,234.56</td>
          <td>Ingreso</td>
          <td>Vigente</td>
        </tr>
        <tr>
          <td>22222222-2222-2222-2222-222222222222</td>
          <td>CCC010101CCC</td>
          <td>EMISOR2</td>
          <td>DDD010101DDD</td>
          <td>RECEPTOR2</td>
          <td>2025-01-20T15:00:00</td>
          <td>2025-01-20T15:00:05</td>
          <td>$500.00</td>
          <td>Egreso</td>
          <td>Cancelado</td>
        </tr>
      </table>
      </body></html>
      """

      results = Consulta.parse_results(html)

      assert length(results) == 2
      first = hd(results)
      assert first.uuid == "11111111-1111-1111-1111-111111111111"
      assert first.rfc_emisor == "AAA010101AAA"
      assert first.nombre_emisor == "EMISOR S.A."
      assert first.total == 1234.56
      assert first.efecto == "Ingreso"
      assert first.estado == "Vigente"

      [_, second] = results
      assert second.uuid == "22222222-2222-2222-2222-222222222222"
      assert second.total == 500.0
      assert second.estado == "Cancelado"
    end

    test "retorna lista vacia si no hay tabla" do
      assert Consulta.parse_results("<html></html>") == []
    end

    test "ignora filas sin UUID" do
      html = """
      <table id="ctl00_MainContent_tblResult">
        <tr><th>UUID</th><th>RfcEmisor</th></tr>
      </table>
      """

      assert Consulta.parse_results(html) == []
    end
  end
end
