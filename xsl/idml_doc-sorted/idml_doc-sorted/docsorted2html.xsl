<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:aid="http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5="http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml="http://transpect.io/idml2xml"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs c idml2xml aid5 aid xhtml tr"
  version="2.0">

<!--  <xsl:import href="../propmap.xsl"/>-->

  <xsl:param name="debug" select="'no'"/>
  <xsl:param name="hub-version" select="'1.2'"/><!-- dependency by propmap -->

  <xsl:template match="/" mode="idml2xml:docsorted2html">
    <html>
      <head>
        <title><xsl:value-of select="replace(*/@xml:base, '^.+/(.+)\.tmp/[^/]+$', '$1')"/></title>
      </head>
      <body>
        <xsl:apply-templates select="*" mode="#current"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="idPkg:Graphic" mode="idml2xml:docsorted2html"/>
  <xsl:template match="idPkg:Styles" mode="idml2xml:docsorted2html"/>
  <xsl:template match="idPkg:Preferences" mode="idml2xml:docsorted2html"/>
  <xsl:template match="EndnoteOption" mode="idml2xml:docsorted2html"/>
  <xsl:template match="idml2xml:hyper" mode="idml2xml:docsorted2html"/>
  <xsl:template match="idml2xml:lang" mode="idml2xml:docsorted2html"/>
  <xsl:template match="idml2xml:cond" mode="idml2xml:docsorted2html"/>
  <xsl:template match="idml2xml:index" mode="idml2xml:docsorted2html"/>
  <xsl:template match="idml2xml:numbering" mode="idml2xml:docsorted2html"/>

  <xsl:template match="Story" mode="idml2xml:docsorted2html">
    <div>
      <xsl:apply-templates select="node()" mode="#current"/>
    </div>
  </xsl:template>
  <xsl:template match="StoryPreference" mode="idml2xml:docsorted2html"/>
  <xsl:template match="InCopyExportOption" mode="idml2xml:docsorted2html"/>

  <xsl:template match="TextFrame" mode="idml2xml:docsorted2html">
    <div>
      <xsl:apply-templates select="@idml2xml:objectstyle, node()" mode="#current"/>
    </div>
  </xsl:template>

  <xsl:template match="Rectangle" mode="idml2xml:docsorted2html">
    <div>
      <xsl:apply-templates select="@idml2xml:objectstyle, node()" mode="#current"/>
    </div>
  </xsl:template>

  <xsl:template match="ParagraphStyleRange" mode="idml2xml:docsorted2html">
    <p>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </p>
  </xsl:template>

  <xsl:template match="Properties" mode="idml2xml:docsorted2html"/>

  <xsl:template match="Br" mode="idml2xml:docsorted2html">
    <br/>
  </xsl:template>

  <xsl:template match="Content" mode="idml2xml:docsorted2html">
    <xsl:analyze-string select="." regex="&#x2028;"><!-- U+2028: line separator-->
      <xsl:matching-substring>
        <br/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:template match="CharacterStyleRange" mode="idml2xml:docsorted2html">
    <span>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </span>
  </xsl:template>

  <xsl:template match="  ParagraphStyleRange/@AppliedParagraphStyle 
                       | CharacterStyleRange/@AppliedCharacterStyle
                       | @idml2xml:objectstyle" mode="idml2xml:docsorted2html">
    <xsl:attribute name="class" select="."/>
  </xsl:template>

  <xsl:template match="@*" mode="idml2xml:docsorted2html"/>

</xsl:stylesheet>
