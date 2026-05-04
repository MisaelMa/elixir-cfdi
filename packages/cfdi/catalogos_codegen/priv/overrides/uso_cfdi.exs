%{
  enum_names: %{
    "G01" => :adquisicion_mercancias,
    "G02" => :devoluciones_descuentos_bonificaciones,
    "G03" => :gastos_en_general,
    "I01" => :construcciones,
    "I02" => :mobiliario_y_equipo_de_oficina,
    "I03" => :equipo_de_transporte,
    "I04" => :equipo_de_computo,
    "I05" => :dados_troqueles_herramental,
    "I06" => :comunicaciones_telefonicas,
    "I07" => :comunicaciones_satelitales,
    "I08" => :otra_maquinaria,
    "D01" => :honorarios_medicos,
    "D02" => :gastos_medicos_por_incapacidad,
    "D03" => :gastos_funerales,
    "D04" => :donativos,
    "D05" => :intereses_por_creditos_hipotecarios,
    "D06" => :aportaciones_voluntarias_sar,
    "D07" => :prima_seguros_gastos_medicos,
    "D08" => :gastos_transportacion_escolar,
    "D09" => :cuentas_ahorro_pensiones,
    "D10" => :servicios_educativos,
    "P01" => :por_definir,
    "S01" => :sin_efectos_fiscales,
    "CP01" => :pagos,
    "CN01" => :nomina
  },
  descriptions: %{
    # "P01" is in the XSD but absent from the XLSX (deprecated code).
    # Canonical description sourced from node-cfdi.
    "P01" => "Por definir"
  }
}
