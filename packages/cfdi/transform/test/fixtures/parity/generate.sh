#!/usr/bin/env bash
# Regenera las cadenas originales esperadas con xsltproc + los XSLT oficiales
# LOCALIZADOS (priv/xslt/4.0). Requiere `xsltproc`. Los tests NO lo necesitan:
# leen expected/*.txt ya generados.
#
#   cd packages/cfdi/transform && test/fixtures/parity/generate.sh
set -euo pipefail
cd "$(dirname "$0")"
XSLT="../../../priv/xslt/4.0/cadenaoriginal_4_0.xslt"
mkdir -p expected
for xml in xml/*.xml; do
  name="$(basename "$xml" .xml)"
  # xsltproc avisa "only 1.1 features are supported" por version="2.0" (modo forward-compatible)
  xsltproc "$XSLT" "$xml" > "expected/$name.txt" 2>/dev/null
  echo "ok $name"
done
