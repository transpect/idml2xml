<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  exclude-result-prefixes = "idPkg aid5 aid xs"
>

  <!--== KEYs ==-->
<!--
  <xsl:key name="topic" match="Topic" use="@Self"/>
  <xsl:key name="hyperlink" match="Hyperlink" use="@Source"/>
  <xsl:key name="destination" match="HyperlinkURLDestination" use="@Self"/>
-->

  <!--== mode: Images ==-->

  <xsl:template match="Rectangle" mode="idml2xml:Images">
    <xsl:variable name="metadata" as="xs:string"
      select="replace(Image/MetadataPacketPreference/Properties/Contents/text(), '\s|\n', '')" />
    <xsl:variable name="dpi-x" as="xs:integer?"
      select="xs:integer(tokenize(Image/@EffectivePpi, ' ')[1])" />
    <xsl:variable name="dpi-y" as="xs:integer?"
      select="xs:integer(tokenize(Image/@EffectivePpi, ' ')[2])" />
    <xsl:variable name="dpi-x-original" as="xs:integer?"
      select="xs:integer(tokenize(Image/@ActualPpi, ' ')[1])" />
    <xsl:variable name="dpi-y-original" as="xs:integer?"
      select="xs:integer(tokenize(Image/@ActualPpi, ' ')[2])" />
    <xsl:variable name="PathPoints" as="node()*"
      select="Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType" />
    <xsl:variable name="CoordinateLeft" as="xs:double"
      select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[1] )" />
    <xsl:variable name="CoordinateTop" as="xs:double"
      select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[2] )" />
    <xsl:variable name="CoordinateRight" as="xs:double"
      select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[1] )" />
    <xsl:variable name="CoordinateBottom" as="xs:double"
      select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[2] )" />
    <xsl:message select="'                top:', $CoordinateTop, ' left:',$CoordinateLeft, ' right:', $CoordinateRight, ' bottom:',$CoordinateBottom"/>
    <image>
      <xsl:if test="descendant::Link/@LinkResourceURI">
        <xsl:attribute name="src" select="descendant::Link/@LinkResourceURI"/>
      </xsl:if>
      <xsl:attribute name="type" select="replace(.//@ImageTypeName,'\$ID/','')"/>
      <xsl:attribute name="width" select="(abs($CoordinateLeft) + abs($CoordinateRight)) * $dpi-x-original div 72"/>
      <xsl:attribute name="height" select="(abs($CoordinateTop) + abs($CoordinateBottom)) * $dpi-y-original div 72"/>
      <xsl:if test="matches(Image/MetadataPacketPreference/Properties/Contents,'exif:PixelXDimension')">
        <xsl:attribute name="width-original" 
          select="replace(
                    $metadata,
                    '^.*exif:PixelXDimension.(\d+).*$',
                    '$1')"/>
        <xsl:attribute name="height-original" 
          select="replace(
                    $metadata,
                    '^.*exif:PixelYDimension.(\d+).*$',
                    '$1')"/>
      </xsl:if>
      <xsl:attribute name="dpi-x" select="$dpi-x" />
      <xsl:attribute name="dpi-y" select="$dpi-y" />
      <xsl:attribute name="dpi-x-original" select="$dpi-x-original" />
      <xsl:attribute name="dpi-y-original" select="$dpi-y-original" />
      <xsl:attribute name="xml:id" select="concat('img_', $idml2xml:basename, '_', @Self)" />
      <xsl:message select="concat('Processing Image, @Self: ', @Self)"/>
    </image>
  </xsl:template>

</xsl:stylesheet>
