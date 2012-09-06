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
    <xsl:apply-templates select="document(@src)" mode="#current"/>
  </xsl:template>

  <xsl:template match="/processing-instruction()" mode="idml2xml:Document" />

  <xsl:template match="/" mode="idml2xml:Document">
    <xsl:document>
      <xsl:apply-templates mode="#current" />
    </xsl:document>
  </xsl:template>

  <xsl:template match="/*" mode="idml2xml:Document">
    <xsl:copy>
      <xsl:namespace name="idml2xml" select="'http://www.le-tex.de/namespace/idml2xml'" />
      <xsl:attribute name="xml:base" select="base-uri(.)" />
      <xsl:copy-of select="@*, /processing-instruction()"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Cell | CharacterStyleRange | HyperlinkTextSource | Footnote
                       | ParagraphStyleRange | Table | XMLElement | Image | EPS | PDF"
    mode="idml2xml:Document">
    <xsl:copy>
      <xsl:attribute name="srcpath" select="idml2xml:srcpath(.)" />
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:function name="idml2xml:srcpath" as="xs:string">
    <xsl:param name="elt" as="element(*)?" />
    <xsl:sequence select="string-join(
                            (
                              if ($elt/.. instance of element(*)) then idml2xml:srcpath($elt/..) else concat(base-uri($elt), '?xpath='),
                              '/',
                              name($elt),
                              '[',
                              xs:string(index-of(for $s in $elt/../*[name() = name($elt)] return generate-id($s), generate-id($elt))),
                              ']'
                            ),
                            ''
                          )"/>
  </xsl:function>



  <idml2xml:default-namespaces>
    <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml"/>
    <XMLAttribute Name="xmlns:aid" Value="http://ns.adobe.com/AdobeInDesign/4.0/"/>
    <XMLAttribute Name="xmlns:aid5" Value="http://ns.adobe.com/AdobeInDesign/5.0/"/>
  </idml2xml:default-namespaces>

  <!--== mode: DocumentStoriesSorted ==-->

  <!-- root template -->
  <xsl:template match="/" mode="idml2xml:DocumentStoriesSorted">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="/Document" mode="idml2xml:DocumentStoriesSorted">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:attribute name="TOCStyle_Title" select="//TOCStyle[@Title ne ''][1]/@Title"/>
      <idml2xml:namespaces>
        <xsl:for-each-group
          select="//XMLAttribute[ @Name[ matches( ., '^xmlns:' ) ] ] 
                  union document('')/*/idml2xml:default-namespaces/XMLAttribute" 
          group-by="@Value">
          <ns short="{substring-after( @Name, ':' )}" space="{@Value}" />
        </xsl:for-each-group>
      </idml2xml:namespaces>
      <xsl:copy-of select="idPkg:Graphic" />
      <xsl:copy-of select="idPkg:Styles" />
      <idml2xml:hyper>
        <xsl:copy-of select="HyperlinkPageDestination | HyperlinkURLDestination | Hyperlink" />
      </idml2xml:hyper>
      <idml2xml:lang>
        <xsl:copy-of select="Language" />
      </idml2xml:lang>
      <xsl:for-each-group select="  idPkg:Spread/Spread/TextFrame
                                  | idPkg:Spread/Spread/Group[TextFrame]" 
        group-by="(@ParentStory, TextFrame/@ParentStory)">
        <xsl:variable name="frame" select="(., TextFrame)[@ParentStory][1]" as="element(TextFrame)" />
        <xsl:if test="count( $frame/Properties/PathGeometry/GeometryPathType ) gt 1">
          <xsl:message select="'WARNING: more than one GeometryPathType element in', $frame/@Self"/>
        </xsl:if>
        <!--
        <xsl:variable name="PathPoints" select="Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType" as="node()*"/>
        <xsl:variable name="CoordinateLeft" select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[1] )" as="xs:double"/>
        <xsl:variable name="CoordinateTop" select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[2] )" as="xs:double"/>
        <xsl:variable name="CoordinateRight" select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[1] )" as="xs:double"/>
        <xsl:variable name="CoordinateBottom" select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[2] )" as="xs:double"/>
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
        <xsl:choose>
          <xsl:when test="self::Group">
            <xsl:apply-templates select="." mode="idml2xml:DocumentResolveTextFrames" />
          </xsl:when>
          <xsl:otherwise><!-- self::TextFrame -->
            <xsl:copy>
              <xsl:copy-of select="@* | node()" />
              <xsl:apply-templates select="key( 'story', current()/@ParentStory )" mode="idml2xml:DocumentResolveTextFrames"/>
            </xsl:copy>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
      <xsl:apply-templates select="//XmlStory, //Spread/Rectangle" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- Usually, Groups contain Frames with different stories (e.g., an image and its caption).
       If every Frame in the group contains the same story, we will dissolve the group and process 
       the first frame. -->
  <xsl:template match="Group
                       [every $child in (* except TextWrapPreference) satisfies $child/self::TextFrame] (: no idea what else to expect :)
                       [count(distinct-values(TextFrame/@ParentStory)) eq 1]" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates select="TextFrame[1]" mode="#current" />
  </xsl:template>

  <xsl:template match="TextFrame" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy>
      <xsl:apply-templates select="@* | *" mode="#current" />
      <xsl:apply-templates select="key( 'story', current()/@ParentStory )" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="TextFrame/*" mode="idml2xml:DocumentResolveTextFrames" />
  <xsl:template match="TextFrame/@*" mode="idml2xml:DocumentResolveTextFrames" priority="0" />
  <xsl:template match="TextFrame/@AppliedObjectStyle" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:attribute name="idml2xml:{local-name()}" select="replace( idml2xml:substr( 'a', ., 'ObjectStyle/' ), '%3a', ':' )" />
  </xsl:template>
  

  <!-- Remove new Story XMLElements, see also idml-specification.pdf page 235-236 -->
  <xsl:template match="XMLElement[ idml2xml:substr( 'a', @MarkupTag, 'XMLTag/' ) = /Document/idPkg:Preferences/XMLPreference/@DefaultStoryTagName  and  @XMLContent ]" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  

</xsl:stylesheet>