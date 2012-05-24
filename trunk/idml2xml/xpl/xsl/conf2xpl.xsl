<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"  
  version="2.0">

  <xsl:output indent="yes"/>

  <xsl:template match="/schematron-checks">
    <p:declare-step version="1.0">
      <p:output port="manually-wrapped">
        <p:pipe step="wrap" port="result"/>
      </p:output>
      <!-- doesn't work with detailed. dunno why. fuck
      <p:output port="result">
        <p:pipe step="{@for-step}" port="result"/>
      </p:output>
      <p:output port="report">
        <p:pipe step="{@name}" port="result"/>
      </p:output>
      -->
      <p:option name="file"/>
      <p:option name="debug" select="'false'"/>
      <p:import href="../xpl/idml2xml.xpl" />
      <p:import href="../xpl/apply-schematron.xpl" />
      <idml2xml:hub name="{@for-step}">
        <p:with-option name="idmlfile" select="$idmlfile"/>
      </idml2xml:hub>
      <p:wrap name="out" wrapper="c:result" match="/"/>
      <p:sink/>

      <xsl:apply-templates />

      <p:wrap-sequence name="{@name}" wrapper="c:reports">
        <p:input port="source">
          <xsl:for-each select="check">
            <p:pipe port="result" step="sch_{@port}" />
          </xsl:for-each>
        </p:input>
      </p:wrap-sequence>
      <p:wrap-sequence name="wrap" wrapper="cx:documents">
        <p:input port="source">
          <p:pipe step="{@name}" port="result" />
          <p:pipe step="out" port="result" />
        </p:input>
      </p:wrap-sequence>
    </p:declare-step>
  </xsl:template>

  <xsl:template match="check">
    <xsl:element name="idml2xml:apply-schematron">
      <xsl:attribute name="name" select="concat('sch_', @port)"/>
      <p:input port="source">
        <p:pipe step="{../@for-step}" port="{@port}"/>
      </p:input>
      <p:input port="schema">
        <p:document href="{resolve-uri(@sch, base-uri(.))}" />
      </p:input>
    </xsl:element>
    <p:sink/>
  </xsl:template>

</xsl:stylesheet>
