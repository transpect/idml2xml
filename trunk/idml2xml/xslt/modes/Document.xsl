<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:saxon = "http://saxon.sf.net/"
    xmlns:letex = "http://www.le-tex.de/namespace"
    xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
    exclude-result-prefixes = "idPkg aid5 aid saxon xs letex"
>
  <!--== KEYs ==-->
  <xsl:key name="story" match="Story" use="@Self"/>

  <!--== mode: Document ==-->
  <xsl:template match=" idPkg:BackingStory |
                        idPkg:Fonts |
                        idPkg:Graphic |
                        idPkg:Mapping |
                        idPkg:MasterSpread | 
                        idPkg:Preferences |
                        idPkg:Spread | 
                        idPkg:Story |
                        idPkg:Styles |
                        idPkg:Tags" 
                mode="idml2xml:Document">
    <xsl:sequence select="document(@src)"/>
  </xsl:template>

  <!-- temporary root-template -->
  <!--<xsl:template match="/" mode="idml2xml:DocumentStoriesSorted">
  <Document><xsl:apply-templates select="//Story" mode="idml2xml:DocumentResolveTextFrames"/><xsl:apply-templates select="//XmlStory" mode="#current"/></Document>
  </xsl:template>-->

  <!-- root-template -->
  <xsl:template match="/" mode="idml2xml:DocumentStoriesSorted">
    <Document>
      <xsl:for-each-group select="Document/idPkg:Spread/Spread/TextFrame" group-by="@ParentStory">
        <!--<xsl:sort select="xs:double( tokenize(@ItemTransform, ' ' )[6] )" order="ascending" />
        <xsl:sort select="xs:double( tokenize(@ItemTransform, ' ' )[5] )" order="ascending" />-->
        <!--<xsl:sort 
          select="xs:double( tokenize( Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType[1]/@Anchor, ' ' )[1] )
                  +
                  xs:double( tokenize(@ItemTransform, ' ' )[5] )"
          order="descending"/>-->
        <xsl:if test="count( Properties/PathGeometry/GeometryPathType ) gt 1">
          <xsl:message select="'WARNING: more than one GeometryPathType element in', @Self"/>
        </xsl:if>
        <xsl:variable name="PathPoints" select="Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType" as="node()*"/>
        <xsl:variable name="CoordinateLeft" select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[1] )" as="xs:double"/>
        <xsl:variable name="CoordinateTop" select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[2] )" as="xs:double"/>
        <xsl:variable name="CoordinateRight" select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[1] )" as="xs:double"/>
        <xsl:variable name="CoordinateBottom" select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[2] )" as="xs:double"/>
        <!--
        <xsl:message select="'top:', $CoordinateTop, ' left:',$CoordinateLeft, ' right:', $CoordinateRight, ' bottom:',$CoordinateBottom"/>
        <xsl:message select="key( 'story', current()/@ParentStory )//Content/text()"/>
        <xsl:message select="@ItemTransform, @ParentStory"/>
        <xsl:message select="''"/>
        -->
          <!-- Coordinations of TextFrame:
          <PathPointArray>
            <PathPoint Anchor="{$left} {$top}" LeftDirection="{$left} {$top}" RightDirection="{$left} {$top}"/>
            <PathPoint Anchor="{$left} {$bottom}" LeftDirection="{$left} {$bottom}" RightDirection="{$left} {$bottom}"/>
            <PathPoint Anchor="{$right} {$bottom}" LeftDirection="{$right} {$bottom}" RightDirection="{$right} {$bottom}"/>
            <PathPoint Anchor="{$right} {$top}" LeftDirection="{$right} {$top}" RightDirection="{$right} {$top}"/>
          </PathPointArray>
        -->
        <!--
        Increasing a vertical coordinate (y) moves the specified location down in pasteboard
coordinates. This is the same as ruler coordinates, but is ?lipped?relative to the x and y axes of
traditional geometry (i.e., what you learned in geometry and trigonometry classes), PostScript,
and PDF.
        -->
        <!-- @ItemTransform: (standard is 1 0 0  1 0 0) last two are x and y -->
        <!-- childs of Spread:
        FlattenerPreference_
        Object?&
        Page_Object*&
        Oval_Object*&
        Rectangle_Object*&
        GraphicLine_
        Object*&
        TextFrame_
        Object*&
        Polygon_Object*&
        Group_Object*&
        EPSText_Object*&
        FormField_
        Object*&
        Button_Object*
        -->
        <xsl:copy>
          <xsl:copy-of select="@* | node()" />
          <xsl:apply-templates select="key( 'story', current()/@ParentStory )" mode="idml2xml:DocumentResolveTextFrames"/>
        </xsl:copy>
      </xsl:for-each-group>
      <xsl:apply-templates select="//XmlStory" mode="#current"/>
    </Document>
  </xsl:template>

  <xsl:template match="TextFrame" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy>
      <xsl:apply-templates select="@* | *" mode="#current" />
      <xsl:apply-templates select="$idml2xml:Document//key( 'story', current()/@ParentStory )" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="TextFrame/*" mode="idml2xml:DocumentResolveTextFrames" />
  <xsl:template match="TextFrame/@*" mode="idml2xml:DocumentResolveTextFrames" priority="0" />
  <xsl:template match="TextFrame/@AppliedObjectStyle" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:attribute name="idml2xml:{local-name()}" select="replace( idml2xml:substr( 'a', ., 'ObjectStyle/' ), '%3a', ':' )" />
  </xsl:template>

  
  <!-- decode attributes (%)-->
  <!--<xsl:template match="@*[ matches( ., '&#x25;' ) ]" mode="idml2xml:Document">
    <xsl:attribute name="{name()}">
      <xsl:value-of select="replace( ., '&#x25;3a', ':' )"/><xsl:message select="replace( ., '&#x25;3a', ':' )" terminate="no"/>
    </xsl:attribute>
    <xsl:if test="not( matches( ., '%3a' ) )">
      <xsl:message select="'WARNING: another encoded sign in attribute value found:', ."/>
    </xsl:if>
  </xsl:template>-->


  <!-- Remove new Story XMLElements, see also idml-specification.pdf page 235-236 -->
  <xsl:variable name="idml2xml:NewStoriesName" select="$idml2xml:Document/Document/idPkg:Preferences/XMLPreference/@DefaultStoryTagName"/>
  <xsl:template match="XMLElement[ idml2xml:substr( 'a', @MarkupTag, 'XMLTag/' ) = $idml2xml:NewStoriesName  and  @XMLContent ]" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="CrossReferenceSource" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>

  <xsl:template match="CrossReferenceSource//Content[. is (ancestor::CrossReferenceSource[1]//Content)[1]]" mode="idml2xml:DocumentResolveTextFrames">
    <idml2xml:genAnchor xml:id="{ancestor::CrossReferenceSource[1]/@Self}"/>
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>