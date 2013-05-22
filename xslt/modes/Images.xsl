<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:letex    = "http://www.le-tex.de/namespace"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  exclude-result-prefixes = "idPkg aid5 aid xs letex"
>

  <!--== KEYs ==-->
<!--
  <xsl:key name="topic" match="Topic" use="@Self"/>
  <xsl:key name="hyperlink" match="Hyperlink" use="@Source"/>
  <xsl:key name="destination" match="HyperlinkURLDestination" use="@Self"/>
-->

  <!--== mode: Images ==-->

  <xsl:template match="*[name() = $idml2xml:shape-element-names]" mode="idml2xml:Images">
    <xsl:variable name="metadata" as="xs:string"
      select="replace(Image/MetadataPacketPreference/Properties/Contents/text(), '\s|\n', '')" />
    <xsl:variable name="dpi-x" as="xs:integer"
      select="if(Image/@EffectivePpi) 
              then xs:integer(tokenize(Image/@EffectivePpi, ' ')[1])
              else 150" />
    <xsl:variable name="dpi-y" as="xs:integer"
      select="if(Image/@EffectivePpi)
              then xs:integer(tokenize(Image/@EffectivePpi, ' ')[2])
              else 150" />
    <xsl:variable name="dpi-x-original" as="xs:string"
      select="if(Image/@ActualPpi)
              then xs:string(tokenize(Image/@ActualPpi, ' ')[1])
              else 'NaN'" />
    <xsl:variable name="dpi-y-original" as="xs:string"
      select="if(Image/@ActualPpi)
              then xs:string(tokenize(Image/@ActualPpi, ' ')[2])
              else 'NaN'" />
    <xsl:variable name="PathPoints" as="node()*"
      select="Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType" />
    <xsl:variable name="suffix" as="xs:string"
      select="letex:identical-self-object-suffix(.)"/>

    <image>
      <xsl:if test="descendant::Link/@LinkResourceURI">
        <xsl:attribute name="src" select="descendant::Link/@LinkResourceURI"/>
      </xsl:if>
      <xsl:attribute name="type" select="replace(.//@ImageTypeName,'\$ID/','')"/>
      <xsl:if test="self::Rectangle">
        <xsl:variable name="CoordinateLeft" as="xs:double"
          select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[1] )"/>
        <xsl:variable name="CoordinateTop" as="xs:double"
          select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[2] )"/>
        <xsl:variable name="CoordinateRight" as="xs:double"
          select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[1] )"/>
        <xsl:variable name="CoordinateBottom" as="xs:double"
          select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[2] )"/>
        <xsl:variable name="width" as="xs:double">
          <xsl:choose>
            <xsl:when test="$CoordinateLeft gt 0 and $CoordinateRight gt 0">
              <xsl:sequence select="$CoordinateRight - $CoordinateLeft"/>
            </xsl:when>
            <xsl:when test="$CoordinateLeft lt 0 and $CoordinateRight lt 0">
              <xsl:sequence select="abs($CoordinateLeft - $CoordinateRight)"/>
            </xsl:when>
            <xsl:when test="$CoordinateLeft lt 0 and $CoordinateRight gt 0">
              <xsl:sequence select="abs($CoordinateLeft) + $CoordinateRight"/>
            </xsl:when>
            <!-- shape transformed, unsupported -->
            <xsl:otherwise>
              <xsl:message select="concat('IDML2XML WARNING: Shape ', local-name(.), ' (', @Self, ') with not yet implemented transformation settings.')"/>
              <xsl:sequence select="xs:double('0')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="height" as="xs:double">
          <xsl:choose>
            <xsl:when test="$CoordinateLeft">
              <xsl:sequence select="$CoordinateBottom - $CoordinateTop"/>
            </xsl:when>
            <!-- shape transformed, unsupported -->
            <xsl:otherwise>
              <xsl:message select="concat('IDML2XML WARNING: Shape ', local-name(.), ' (', @Self, ') with not yet implemented transformation settings.')"/>
              <xsl:sequence select="xs:double('0')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:attribute name="width"
          select="$width * $dpi-x div 72"/>
        <xsl:attribute name="height"
          select="$height"/>
<!--
      <xsl:message select="concat('Processing shape ', local-name(), ', @Self: ', @Self, 
                                  ', Linked image filename: ', tokenize(descendant::Link[1]/@LinkResourceURI, '/')[last()])"/>
      <xsl:message select="'       top:', $CoordinateTop, 
                           '&#xa;      left:', $CoordinateLeft, 
                           '&#xa;     right:', $CoordinateRight, 
                           '&#xa;    bottom:', $CoordinateBottom, 
                           '&#xa;width (pt):', $width,
                           '&#xa;height(pt):', $height,
                           '&#xa;width (px):', $width * $dpi-x div 72, ' (= width in pt * actual dpi-x div 72; dpi-x =', $dpi-x, ')',
                           '&#xa;height(px):', $height * $dpi-y div 72, ' (= height in pt * actual dpi-y div 72; dpi-y =', $dpi-y, ')', '&#xa;'"/>
-->
      </xsl:if>
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
      <xsl:attribute name="xml:id" select="concat('img_', $idml2xml:basename, '_', @Self, letex:identical-self-object-suffix(.))" />
    </image>
  </xsl:template>

</xsl:stylesheet>
