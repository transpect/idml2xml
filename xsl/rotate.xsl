<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:idml2xml="http://transpect.io/idml2xml" 
  xmlns:tr="http://transpect.io" 
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs idml2xml tr css math css"
  version="3.0">
  
  <xsl:variable name="idml2xml:rad2deg" as="xs:double" select="180 div math:pi()"/>
  
  <!-- see https://www.indiscripts.com/blog/public/data/coordinate-spaces-and-transformations-5/CoordinateSpacesTransfos01-05.pdf -->
  
  <xsl:function name="idml2xml:ItemTransform2css" as="element(css:transform)">
    <xsl:param name="it" as="attribute(ItemTransform)+"/>
    <xsl:param name="ppa" as="element(PathPointArray)"/><!-- 1st in PathPointArray, that is, top left -->
    <xsl:variable name="id" as="attribute(ItemTransform)">
      <xsl:attribute name="ItemTransform" select="'1 0 0 1 0 0'"/>
    </xsl:variable>
    <xsl:variable name="chained" as="attribute(ItemTransform)" select="idml2xml:chain-ItemTransforms($it)"/>
    <xsl:variable name="it-tokens" as="xs:double+" select="tokenize($chained) ! number(.)"/>
    <xsl:variable name="acos" as="xs:double" select="math:acos($it-tokens[1])"/>
    <xsl:variable name="beyond-180" as="xs:boolean" select="$it-tokens[2] gt 0"/>
    <xsl:variable name="angle-deg" as="xs:double" select="if ($beyond-180)
                                                          then 360 - $acos *$idml2xml:rad2deg 
                                                          else $acos * $idml2xml:rad2deg"/>
    <xsl:variable name="ppt-upper-left-tokens" as="xs:double+" select="tokenize($ppa/PathPointType[1]/@Anchor) ! number(.)"/>
    <xsl:variable name="ul-vec" as="map(xs:string, xs:double)" 
      select="map{'x':$ppt-upper-left-tokens[1], 'y':$ppt-upper-left-tokens[2]}"/>
    <xsl:variable name="new-ul-vec" as="map(xs:string, xs:double)" select="idml2xml:apply-ItemTransform($chained, $ul-vec)"/>
    <css:transform>
      <xsl:attribute name="id" select="lower-case(local-name($it[1]/..)) || '_' || $it[1]/../@Self"/>
      <xsl:attribute name="rotate" select="round(360 - $angle-deg,5) || 'deg'"/>
      <xsl:attribute name="top" select="round($new-ul-vec?y,5)"/>
      <xsl:attribute name="left" select="round($new-ul-vec?x,5)"/>
      <xsl:attribute name="transform-origin" select="'top left'"/>
    </css:transform>
  </xsl:function>
  
  <xsl:function name="idml2xml:chain-ItemTransforms" as="attribute(ItemTransform)">
    <xsl:param name="it" as="attribute(ItemTransform)*"/>
    <xsl:choose>
      <xsl:when test="count($it) = 0">
        <xsl:attribute name="ItemTransform" select="'1.0 0 0 1 0 0'"/>
      </xsl:when>
      <xsl:when test="count($it) = 1">
        <xsl:sequence select="$it"/>
      </xsl:when>
      <xsl:otherwise>
        <!--<xsl:if test="not($it[1] = '1 0 0 1 0 0')">
        <xsl:message select="'IIIIIIIIII ', $it"></xsl:message>
          <xsl:message select="'JJJJJJJJ ', idml2xml:chain-ItemTransforms(subsequence($it, 2))"></xsl:message>
        <xsl:variable name="_1" select="tokenize($it[1]) ! number(.)" as="xs:double+"/>
        <xsl:variable name="_2" select="tokenize(idml2xml:chain-ItemTransforms(subsequence($it, 2))) ! number(.)" as="xs:double+"/>
        <xsl:if test="count($it) = 2"><xsl:message>
          <xsl:value-of select="'KKKKKKK'"/>
          <xsl:attribute name="ItemTransform" separator=" ">
          <xsl:sequence select="$_1[1] * $_2[1] + $_1[2] * $_2[3]"/>
          <xsl:sequence select="$_1[1] * $_2[2] + $_1[2] * $_2[4]"/>
          <xsl:sequence select="$_1[3] * $_2[1] + $_1[4] * $_2[3]"/>
          <xsl:sequence select="$_1[3] * $_2[2] + $_1[4] * $_2[4]"/>
          <xsl:sequence select="$_1[5] * $_2[1] + $_1[6] * $_2[3] + $_2[5]"/>
          <xsl:sequence select="$_1[5] * $_2[2] + $_1[6] * $_2[4] + $_2[6]"/>
        </xsl:attribute></xsl:message></xsl:if>

        </xsl:if>-->
        
        <xsl:variable name="_1" select="tokenize($it[1]) ! number(.)" as="xs:double+"/>
        <xsl:variable name="_2" select="tokenize(idml2xml:chain-ItemTransforms(subsequence($it, 2))) ! number(.)" as="xs:double+"/>
        <xsl:attribute name="ItemTransform" separator=" ">
          <xsl:sequence select="$_1[1] * $_2[1] + $_1[2] * $_2[3]"/>
          <xsl:sequence select="$_1[1] * $_2[2] + $_1[2] * $_2[4]"/>
          <xsl:sequence select="$_1[3] * $_2[1] + $_1[4] * $_2[3]"/>
          <xsl:sequence select="$_1[3] * $_2[2] + $_1[4] * $_2[4]"/>
          <xsl:sequence select="$_1[5] * $_2[1] + $_1[6] * $_2[3] + $_2[5]"/>
          <xsl:sequence select="$_1[5] * $_2[2] + $_1[6] * $_2[4] + $_2[6]"/>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="idml2xml:apply-ItemTransform" as="map(xs:string, xs:double)"><!-- keys x and y -->
    <xsl:param name="transform" as="attribute(ItemTransform)"/>
    <xsl:param name="vec" as="map(xs:string, xs:double)"/>
    <xsl:variable name="t" select="tokenize($transform) ! number(.)" as="xs:double+"/>
    <xsl:map>
      <xsl:map-entry key="'x'" select="$vec?x * $t[1] + $vec?y * $t[3] + $t[5]"/>
      <xsl:map-entry key="'y'" select="$vec?x * $t[2] + $vec?y * $t[4] + $t[6]"/>
    </xsl:map>
  </xsl:function>
  
  <xsl:variable name="rotation-input" as="element(input)">
    <input ItemTransform="{math:sqrt(2) div 2} .1 0 1 4 5">
      <PathPointArray>
        <PathPointType Anchor="40.18503937007874 -389.97244094488195"
          LeftDirection="40.18503937007874 -389.97244094488195" RightDirection="40.18503937007874 -389.97244094488195"/>
        <PathPointType Anchor="40.18503937007874 389.26377952832286"
          LeftDirection="40.18503937007874 389.26377952832286" RightDirection="40.18503937007874 389.26377952832286"/>
        <PathPointType Anchor="553.6732283464568 389.26377952832286"
          LeftDirection="553.6732283464568 389.26377952832286" RightDirection="553.6732283464568 389.26377952832286"/>
        <PathPointType Anchor="553.6732283464568 -389.97244094488195"
          LeftDirection="553.6732283464568 -389.97244094488195" RightDirection="553.6732283464568 -389.97244094488195"/>
      </PathPointArray>
    </input>
  </xsl:variable>
  
  <xsl:template name="rotation-test">
    <xsl:message select="idml2xml:ItemTransform2css($rotation-input/@ItemTransform, $rotation-input/PathPointArray)"/>
  </xsl:template>
</xsl:stylesheet>
