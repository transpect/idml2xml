<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xslout="bogo"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0"
  >

  <xsl:output method="xml" indent="yes"  />

  <xsl:namespace-alias stylesheet-prefix="xslout" result-prefix="xsl"/>

  <xsl:template match="/">
    <xslout:stylesheet
      version="2.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
      xmlns:xs="http://www.w3.org/2001/XMLSchema" 
      xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
      xmlns:css="http://www.w3.org/1996/css"
      xmlns:s="http://purl.oclc.org/dsdl/schematron"
      xmlns:html="http://www.w3.org/1999/xhtml"
      xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
      xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
      xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
      xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
      exclude-result-prefixes="svrl s xs html idml2xml"
      >

      <xslout:template match="/*">
        <xslout:copy>
          <xslout:namespace name="idml2xml" select="'http://www.le-tex.de/namespace/idml2xml'" />
          <xslout:apply-templates select="@* | node()" mode="#current" />
        </xslout:copy>
      </xslout:template>

      <xslout:template match="@* | *" mode="#default">
        <xslout:copy>
          <xslout:apply-templates select="@* | node()" mode="#current" />
        </xslout:copy>
      </xslout:template>

      <xslout:template match="@idml2xml:srcpath" mode="#default" />

      <xsl:for-each-group
        select="collection()//svrl:text[s:span[@class eq 'srcpath'] ne '']"
        group-by="tokenize(s:span[@class eq 'srcpath'], '\s+')">
        <xslout:template match="*[contains(@idml2xml:srcpath, '{current-grouping-key()}')]">
          <xslout:copy>
            <xslout:apply-templates select="@*" mode="#current" />
            <xsl:apply-templates select="current-group()" mode="create-message" />
            <xslout:apply-templates mode="#current" />
          </xslout:copy>
        </xslout:template>
      </xsl:for-each-group>
    </xslout:stylesheet>
  </xsl:template>

  <xsl:template match="svrl:text[s:span[@class eq 'srcpath'] ne '']" mode="create-message">
    <xslout:processing-instruction name="idml2xml">
      <xsl:value-of select="../@role"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="../@id"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="text()"/>
    </xslout:processing-instruction>
  </xsl:template>

  <xsl:template match="svrl:text[span[@class eq 'srcpath'] eq '']" mode="#default" />

  <xsl:function name="idml2xml:contains" as="xs:boolean">
    <xsl:param name="containing-string" as="xs:string" />
    <xsl:param name="contained-string" as="xs:string" />
    <xsl:sequence select="$contained-string = tokenize($containing-string, '\s+')" />
  </xsl:function>


</xsl:stylesheet>