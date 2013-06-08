<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  exclude-result-prefixes=" aid5 aid xs"
>

  <!-- 
    Generates XMLElements and the like for generated paragraphs (idml2xml:genPara)
    and the like. These will be converted to proper XML elements in the next pass 
    (which is ExtractTagging).
  -->

  <xsl:template match="Document[not(XmlStory)]" mode="idml2xml:GenerateTagging">
    <xsl:variable name="max-story-length" select="(0, max(for $s in TextFrame/Story return string-length($s)))[last()]" as="xs:integer"/>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="#current" >
        <xsl:with-param name="max-story-length" select="$max-story-length" />
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Story[not(ParagraphStyleRange)]" mode="idml2xml:GenerateTagging">
    <xsl:param name="max-story-length" as="xs:integer?" />
    <xsl:element name="{if (string-length(.) = $max-story-length) then 'XmlStory' else local-name()}">
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="#current" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="Story[ParagraphStyleRange[XMLElement]]" mode="idml2xml:GenerateTagging">
    <xsl:param name="max-story-length" as="xs:integer?" />
    <xsl:element name="{if (string-length(.) = $max-story-length) then 'XmlStory' else local-name()}">
      <xsl:copy-of select="@*" />
      <xsl:for-each-group select="*" group-adjacent="boolean(self::ParagraphStyleRange)">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <XMLElement MarkupTag="XMLTag/idml2xml%3agenDoc">
              <xsl:attribute name="srcpath" select="current-group()/@srcpath" />
              <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
              <xsl:apply-templates select="current-group()" mode="#current" />
            </XMLElement>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>
  
  <xsl:function name="idml2xml:contains-significant-content" as="xs:boolean">
    <xsl:param name="style-range" as="element(*)"/>
    <xsl:sequence select="(
                            some $c in $style-range/descendant::Content[idml2xml:same-scope(., $style-range)] 
                            satisfies (
                              matches($c, '[^&#xfeff;]')
                              or $c/processing-instruction(ACE)
                            )
                          )
                          or
                          $style-range/descendant::TextVariableInstance[idml2xml:same-scope(., $style-range)]/@ResultText 
                          "/>
  </xsl:function>

  <!-- Matches a ParagraphStyleRange that contains both (at least) one tagged para *and* some out-of-para text -->
  <xsl:template match="*:ParagraphStyleRange
                         [.//XMLElement[idml2xml:same-scope(., current())]/XMLAttribute/@Name = 'aid:pstyle']
                         [ some $a in (. | .//XMLElement[idml2xml:same-scope(., current())][not(XMLAttribute/@Name = 'aid:pstyle')])
                           /*[self::CharacterStyleRange or self::HyperlinkTextSource[CharacterStyleRange]][
                             idml2xml:contains-significant-content(.)
                           ]/@AppliedCharacterStyle 
                           satisfies (matches($a, '^CharacterStyle/'))
                         ]" mode="idml2xml:GenerateTagging">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="Properties" />
      <XMLElement MarkupTag="XMLTag/idml2xml%3agenPara">
        <xsl:apply-templates select="* except Properties" mode="#current" />
        <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
        <XMLAttribute Name="aid:pstyle" Value="{idml2xml:StyleName(@AppliedParagraphStyle)}"/>
        <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'gp2'), ' ')}" />
      </XMLElement>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="XmlStory[matches(string-join(.//Content, ''), '^&#xfeff;$')]" mode="idml2xml:GenerateTagging" />

  <!-- Matches a ParagraphStyleRange that contains some text -->
  <xsl:template match="*:ParagraphStyleRange
                         [ancestor::Story]
                         [not(.//XMLElement[idml2xml:same-scope(., current())]/XMLAttribute/@Name = 'aid:pstyle')]
                         [ 
                           some $a in (CharacterStyleRange | HyperlinkTextSource/CharacterStyleRange)[
                             idml2xml:contains-significant-content(.)
                           ]/@AppliedCharacterStyle 
                           satisfies (matches($a, '^CharacterStyle/'))
                         ]" mode="idml2xml:GenerateTagging" priority="0.3">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="Properties" />
      <XMLElement MarkupTag="XMLTag/idml2xml%3agenPara">
        <xsl:apply-templates select="* except Properties" mode="#current" />
        <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
        <XMLAttribute Name="aid:pstyle" Value="{idml2xml:StyleName(@AppliedParagraphStyle)}"/>
        <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'gp4'), ' ')}" />
      </XMLElement>
    </xsl:copy>
  </xsl:template>

  <!-- Matches a ParagraphStyleRange that contains a table or a group -->
  <xsl:template match="ParagraphStyleRange
                         [not(.//XMLElement[idml2xml:same-scope(., current())]/XMLAttribute/@Name = 'aid:pstyle')]
                         [Table or Group]" mode="idml2xml:GenerateTagging">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="Properties" />
      <XMLElement MarkupTag="XMLTag/idml2xml%3agenPara">
        <xsl:apply-templates select="* except Properties" mode="#current" />
        <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
        <XMLAttribute Name="aid:pstyle" Value="{idml2xml:StyleName(@AppliedParagraphStyle)}"/>
        <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'gp5'), ' ')}" />
      </XMLElement>
    </xsl:copy>
  </xsl:template>

  <!-- Fallback, i.e. empty (no text) paragraph with (resolved) anchored textframe in it -->
  <xsl:template match="ParagraphStyleRange" mode="idml2xml:GenerateTagging" priority="-0.9">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="Properties" />
      <XMLElement MarkupTag="XMLTag/idml2xml%3agenPara">
        <xsl:apply-templates select="* except Properties" mode="#current" />
        <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
        <XMLAttribute Name="aid:pstyle" Value="{idml2xml:StyleName(@AppliedParagraphStyle)}"/>
        <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'gp5'), ' ')}" />
      </XMLElement>
    </xsl:copy>
  </xsl:template>


  <!-- If there is exactly 1 XMLElement immediately below a Cell, it is supposed that this element
       represents a table cell. In all other cases, an idml2xml:genCell XMLElement will be created: -->
  <xsl:template match="Cell[not(XMLElement and count(*) eq 1)]" mode="idml2xml:GenerateTagging">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="Properties" />
      <XMLElement MarkupTag="XMLTag/idml2xml%3agenCell">
        <xsl:apply-templates select="* except Properties" mode="#current" />
        <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
        <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'gp7'), ' ')}" />
      </XMLElement>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Table" mode="idml2xml:GenerateTagging">
    <XMLElement MarkupTag="XMLTag/idml2xml%3agenTable">
      <xsl:copy>
        <xsl:copy-of select="@*" />
        <xsl:copy-of select="Properties" />
        <xsl:apply-templates select="* except Properties" mode="#current" />
      </xsl:copy>
      <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
      <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'gp7'), ' ')}" />
    </XMLElement>
  </xsl:template>

  <xsl:template match="*:XMLElement" mode="idml2xml:GenerateTagging">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
  </xsl:template>

  <!-- Matches a ParagraphStyleRange/XMLElement that contains something tagged but without pstyle -->
  <xsl:template match="ParagraphStyleRange
                         [count(XMLElement) eq 1]
                         [every $x in descendant::XMLElement
                           [ancestor::ParagraphStyleRange[1] is current()/..]
                           satisfies (
                             not($x/XMLAttribute[@Name = 'aid:pstyle'])
                           )
                         ]
                         [every $c in (CharacterStyleRange | HyperlinkTextSource/CharacterStyleRange) satisfies (matches($c, '^$'))]
                       /XMLElement
                         [not(every $c in * satisfies ($c/self::Table or $c/self::XMLAttribute))]" mode="idml2xml:GenerateTagging">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="#current" />
      <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
      <XMLAttribute Name="idml2xml:AppliedParagraphStyle" Value="{replace(../@AppliedParagraphStyle, '^ParagraphStyle/', '')}" />
      <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'gp3'), ' ')}" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="CharacterStyleRange[node()][.//*[name() = $idml2xml:idml-content-element-names]]" mode="idml2xml:GenerateTagging">
    <XMLElement MarkupTag="XMLTag/idml2xml%3agenSpan">
      <xsl:copy-of select="@* except @AppliedCharacterStyle"/>
      <XMLAttribute Name="aid:cstyle" Value="{idml2xml:StyleName(@AppliedCharacterStyle)}" />
      <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
      <xsl:apply-templates mode="#current" />
    </XMLElement>
  </xsl:template>


  <xsl:template match="CharacterStyleRange/TextFrame | Group | Group/TextFrame" mode="idml2xml:GenerateTagging">
    <XMLElement MarkupTag="XMLTag/idml2xml%3agenFrame">
      <xsl:apply-templates select="* except Properties" mode="#current" />
      <XMLAttribute Name="idml2xml:elementName" Value="{name()}" />
      <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
      <xsl:apply-templates select="@*:objectstyle" mode="#current" />
    </XMLElement>
  </xsl:template>

  <xsl:template match="@*:objectstyle[. = ('$ID/[None]', '$ID/[Normal Text Frame]')]" mode="idml2xml:GenerateTagging"/>

  
</xsl:stylesheet>
