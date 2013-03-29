<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  exclude-result-prefixes="aid xs idml2xml">

  <!-- mode: idml2xml:JoinSpans -->
  
  <xsl:template match="*[*[@aid:cstyle]]" mode="idml2xml:JoinSpans">
    <xsl:copy >
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:for-each-group select="node()" group-adjacent="idml2xml:phrase-signature(.)">
        <xsl:choose>
          <xsl:when test="self::*[@aid:cstyle]">
            <xsl:variable name="inner" as="node()*">
              <xsl:apply-templates select="current-group()" mode="idml2xml:JoinSpans-unwrap"/>
            </xsl:variable>
            <xsl:if test="$inner">
              <xsl:copy>
                <xsl:if test="$srcpaths = 'yes'">
                  <xsl:attribute name="srcpath" select="current-group()/@srcpath"/>
                </xsl:if>
                <xsl:copy-of select="@* except @srcpath"/>
                <xsl:sequence select="$inner"/>
              </xsl:copy>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="idml2xml:attr-hashes" as="xs:string*">
    <xsl:param name="elt" as="node()*" />
    <xsl:perform-sort>
      <xsl:sort/>
      <xsl:sequence select="for $a in ($elt/@*[not(name() = ('xml:id', 'srcpath', 'idml2xml:reason'))]) return idml2xml:attr-hash($a)" />
    </xsl:perform-sort>
  </xsl:function>
  
  <xsl:function name="idml2xml:attr-hash" as="xs:string">
    <xsl:param name="att" as="attribute(*)" />
    <xsl:sequence select="concat(name($att), '__=__', $att)" />
  </xsl:function>
  
  <xsl:function name="idml2xml:attname" as="xs:string">
    <xsl:param name="hash" as="xs:string" />
    <xsl:value-of select="replace($hash, '__=__.+$', '')" />
  </xsl:function>
  
  <xsl:function name="idml2xml:attval" as="xs:string">
    <xsl:param name="hash" as="xs:string" />
    <xsl:value-of select="replace($hash, '^.+__=__', '')" />
  </xsl:function>
  
  <xsl:function name="idml2xml:signature" as="xs:string*">
    <xsl:param name="elt" as="element(*)?" />
    <xsl:sequence select="if (exists($elt)) 
      then string-join((name($elt), idml2xml:attr-hashes($elt)), '___')
      else '' " />
  </xsl:function>
  
  <!-- If a span, return its hash. 
       If a whitespace text node in between two spans of same hash, return their hash.
       Otherwise, return the empty string. -->
  <xsl:function name="idml2xml:phrase-signature" as="xs:string">
    <xsl:param name="node" as="node()" />
    <xsl:sequence select="if ($node/self::*[@aid:cstyle]) 
                          then idml2xml:signature($node)
                          else 
                            if ($node/self::*)
                            then ''
                            else
                              if ($node/self::text()
                                    [matches(., '^[\p{Zs}\s]+$')]
                                    [idml2xml:signature($node/preceding-sibling::*[1]) eq idml2xml:signature($node/following-sibling::*[1])]
                                 )
                              then idml2xml:signature($node/preceding-sibling::*[1])
                              else ''
                          " />
  </xsl:function>

  <xsl:template match="*[@aid:cstyle]" mode="idml2xml:JoinSpans-unwrap">
    <xsl:apply-templates mode="idml2xml:JoinSpans" />
  </xsl:template>

</xsl:stylesheet>