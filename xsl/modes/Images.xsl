<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  exclude-result-prefixes = "idPkg aid5 aid xs tr"
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
    <xsl:variable name="dpi-x" as="xs:double"
      select="if(Image/@EffectivePpi castable as xs:double) 
              then xs:double(tokenize(Image/@EffectivePpi, ' ')[1])
              else 150" />
    <xsl:variable name="dpi-y" as="xs:double"
      select="if(Image/@EffectivePpi castable as xs:double)
              then xs:double(tokenize(Image/@EffectivePpi, ' ')[2])
              else 150" />
    <xsl:variable name="dpi-x-original" as="xs:double"
      select="if(Image/@ActualPpi)
              then xs:double(tokenize(Image/@ActualPpi, ' ')[1])
              else 150" />
    <xsl:variable name="dpi-y-original" as="xs:double"
      select="if(Image/@ActualPpi)
              then xs:double(tokenize(Image/@ActualPpi, ' ')[2])
              else 150" />
    <xsl:variable name="suffix" as="xs:string"
      select="tr:identical-self-object-suffix(.)"/>

    <image>
      <xsl:if test="descendant::Link/@LinkResourceURI">
        <xsl:attribute name="src" select="descendant::Link/@LinkResourceURI"/>
      </xsl:if>
      <xsl:attribute name="type" select="replace(.//@ImageTypeName,'\$ID/','')"/>
      <xsl:if test="self::Rectangle">
        <xsl:variable name="width" select="idml2xml:get-shape-width(.)" as="xs:double"/>
        <xsl:variable name="height" select="idml2xml:get-shape-height(.)" as="xs:double"/>
        <xsl:attribute name="width"
          select="$width * $dpi-x-original div 72"/>
        <xsl:attribute name="height"
          select="$height * $dpi-y-original div 72"/>

        <xsl:attribute name="shape-width"
          select="concat($width, 'pt')"/>
        <xsl:attribute name="shape-height"
          select="concat($height, 'pt')"/>
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
      <xsl:attribute name="dpi-x" select="if(Image/@EffectivePpi) then $dpi-x else 'nil'" />
      <xsl:attribute name="dpi-y" select="if(Image/@EffectivePpi) then $dpi-y else 'nil'" />
      <xsl:attribute name="dpi-x-original" select="if(Image/@EffectivePpi) then $dpi-x-original else 'nil'" />
      <xsl:attribute name="dpi-y-original" select="if(Image/@EffectivePpi) then $dpi-y-original else 'nil'" />
      <xsl:attribute name="xml:id" select="concat('img_', $idml2xml:basename, '_', @Self, tr:identical-self-object-suffix(.))" />
      <xsl:if test="*[self::PDF | self::Image]/@CustomAltText[matches(., '\S')]">
        <xsl:attribute name="alt" select="*[self::PDF | self::Image]/@CustomAltText"/>
      </xsl:if>
    </image>
  </xsl:template>

</xsl:stylesheet>
