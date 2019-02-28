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
  exclude-result-prefixes="xs c idml2xml aid5 aid xhtml tr cx"
  version="2.0">

  <xsl:param name="debug" select="'no'"/>
  
  <xsl:param name="out-dir-replacement" select="'.idml.out/'"/>
  <xsl:param name="disable-images" select="'no'"/>
  <xsl:param name="zip-file-uri" as="xs:string" />

  <xsl:template match="node() | @*" mode="idml2xml:identity idml2xml:modify">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@xml:base"  mode="idml2xml:export"/>
  
  <xsl:template match="*:Link/@LinkResourceURI"  mode="idml2xml:modify">
    <xsl:if test="$disable-images = ('no', 'false', '')">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@xml:base" mode="idml2xml:modify">
    <xsl:attribute name="{name()}" 
      select="if($out-dir-replacement eq '.idml.out/') 
              then replace(., '\.idml\.tmp/', '.idml.out/')
              else replace(., '\.idml\.tmp/', $out-dir-replacement)"/>
  </xsl:template>

  <xsl:template match="*:Document" mode="idml2xml:export" priority="3">
    <xsl:variable name="basename" select="c:relative-name(@xml:base)" as="xs:string" />
    <xsl:variable name="uri" select="concat($zip-file-uri, '.tmp/', $basename)" as="xs:string" />
    <xsl:result-document href="{$uri}">
      <xsl:processing-instruction name="aid">name="<xsl:value-of select="name()"/>" style="50" type="document" readerVersion="6.0" featureSet="257" product="8.0(370)"</xsl:processing-instruction>
      <xsl:copy>
        <xsl:apply-templates select="@*, node()" mode="export-just-this" />
      </xsl:copy>
    </xsl:result-document>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <c:files>
         <c:entry href="{$uri}" name="{$basename}" method="deflated" level="default" />
          <xsl:apply-templates select="node()" mode="#current"/>
      </c:files>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="c:relative-name" as="xs:string">
    <xsl:param name="uri" as="xs:string" />
    <xsl:sequence select="replace($uri, '^.+\.out/+', '')" />
  </xsl:function>
  
  <xsl:template match="*[@xml:base]" mode="idml2xml:export"  priority="2">
    <xsl:variable name="basename" select="c:relative-name(@xml:base)" as="xs:string" />
    <xsl:variable name="uri" select="concat($zip-file-uri, '.tmp/', $basename)" as="xs:string" />
    <xsl:result-document href="{$uri}">
      <xsl:copy>
        <xsl:apply-templates select="@* | node()" mode="export-just-this" />
      </xsl:copy>
    </xsl:result-document>
    <c:entry href="{$uri}" name="{$basename}" method="deflated" level="default" />
    <xsl:apply-templates mode="#current" />
  </xsl:template>
  
  <xsl:template match="@xml:base" mode="export-just-this" />
  
  <xsl:template match="*[@xml:base]" mode="export-just-this">
    <xsl:copy copy-namespaces="no">
      <xsl:attribute name="src" select="c:relative-name(@xml:base)" />
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@* | * | processing-instruction()" mode="export-just-this">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@* | processing-instruction() | comment() | text()" mode="idml2xml:export" />

</xsl:stylesheet>
