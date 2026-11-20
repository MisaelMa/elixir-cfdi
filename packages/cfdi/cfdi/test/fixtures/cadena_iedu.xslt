<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:iedu="http://www.sat.gob.mx/iedu">
  <xsl:output method="text" encoding="UTF-8" indent="no"/>
  <xsl:include href="../../../../files/4.0/complementos/utilerias.xslt"/>
  <xsl:include href="../../../../files/4.0/complementos/iedu.xslt"/>
  <xsl:template match="/">
    <xsl:text>|</xsl:text>
    <xsl:apply-templates select="//iedu:instEducativas"/>
    <xsl:text>||</xsl:text>
  </xsl:template>
</xsl:stylesheet>
