<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  xmlns:p="http://www.w3.org/ns/xproc" 
  version="2.0">

  <xsl:output indent="yes"/>

  <xsl:template match="/schematron-checks">
    <p:group>
      <p:output port="result" sequence="true">
        <p:pipe step="{@name}" port="result"/>
      </p:output>
      <xsl:apply-templates />
      <p:identity name="{@name}">
        <p:input port="source">
          <xsl:for-each select="check">
            <p:pipe port="result" step="{@port}" />
          </xsl:for-each>
        </p:input>
      </p:identity>
    </p:group>
  </xsl:template>

  <xsl:template match="check">
    <xsl:element name="idml2xml:apply-schematron">
      <xsl:attribute name="name" select="@port"/>
      <p:input port="source">
        <p:pipe step="{../@for-step}" port="{@port}"/>
      </p:input>
      <p:input port="schema">
        <p:document href="{resolve-uri(@sch, base-uri(.))}" />
      </p:input>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
