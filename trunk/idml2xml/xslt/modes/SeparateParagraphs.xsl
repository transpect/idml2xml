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


  <!-- In order to generate tagging for previously untagged content,
       it's important to immediately surround every paragraph with
       the ParagraphStyleRange that is in force there (SeparateParagraphs).
       -->


  <!-- If a ParagraphStyleRange contains at least one XMLElement which contains many paragraphs 
       (i.e., at least one Br between two chunks of text), then the ParagraphStyleRange will
       be pulled inside the XMLElement. Other elements will be wrapped by the ParagraphStyleRange.
       -->
  <xsl:template
    match="ParagraphStyleRange[XMLElement[idml2xml:has-many-paras(.)]][CharacterStyleRange[.//Content[idml2xml:same-scope(., current())]]]" 
    mode="idml2xml:SeparateParagraphs-pull-down-psrange">
    <xsl:variable name="context" select="." as="element(ParagraphStyleRange)" />
    <xsl:for-each-group select="*" group-adjacent="boolean(self::XMLElement)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:apply-templates select="current-group()" mode="idml2xml:SeparateParagraphs-pull-down-psrange_XMLElement" />
        </xsl:when>
        <xsl:otherwise>
          <ParagraphStyleRange>
            <xsl:copy-of select="$context/@*" />
            <xsl:attribute name="srcpath" select="current-group()/@srcpath" />
            <xsl:apply-templates select="current-group()" mode="#current" />
          </ParagraphStyleRange>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <!-- This is for the case
       PSR
         CSR(empty)
         XMLE
         BR
         XMLE
       The preceding template has higher priority.
       -->
  <xsl:template
    match="ParagraphStyleRange[XMLElement][.//CharacterStyleRange[.//Br[idml2xml:same-scope(., current())]]]" 
    mode="idml2xml:SeparateParagraphs-pull-down-psrange"
    priority="2.5">
    <xsl:variable name="context" select="." as="element(ParagraphStyleRange)" />
    <xsl:for-each-group select="*" group-adjacent="boolean(self::XMLElement)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:apply-templates select="current-group()" mode="idml2xml:SeparateParagraphs-pull-down-psrange_XMLElement" />
        </xsl:when>
        <xsl:otherwise>
          <ParagraphStyleRange>
            <xsl:copy-of select="$context/@*" />
            <xsl:attribute name="srcpath" select="current-group()/@srcpath" />
            <xsl:apply-templates select="current-group()" mode="#current" />
          </ParagraphStyleRange>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template
    match="XMLElement" 
    mode="idml2xml:SeparateParagraphs-pull-down-psrange_XMLElement">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:for-each-group select="*" group-adjacent="boolean(self::XMLElement[idml2xml:has-many-paras(.)])">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:apply-templates select="current-group()" mode="idml2xml:SeparateParagraphs-pull-down-psrange_XMLElement" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="{name(ancestor::ParagraphStyleRange[1])}">
              <xsl:copy-of select="ancestor::ParagraphStyleRange[1]/@*" />
              <xsl:apply-templates select="current-group()[not(self::XMLAttribute)]" mode="idml2xml:SeparateParagraphs-pull-down-psrange" />
            </xsl:element>
            <xsl:copy-of select="current-group()/self::XMLAttribute" />
            <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml" />
            <XMLAttribute Name="idml2xml:reason" Value="{string-join((@idml2xml:reason, 'ps2'), ' ')}" />
          </xsl:otherwise>
        </xsl:choose>
      <xsl:copy-of select="XMLAttribute" />
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template
    match="*" 
    mode="idml2xml:SeparateParagraphs-pull-down-psrange_XMLElement">
    <xsl:apply-templates mode="idml2xml:SeparateParagraphs-pull-down-psrange" />
  </xsl:template>


  <!-- Last ParagraphStyleRange of a Story or XmlStory -->
  <xsl:template
    match="ParagraphStyleRange[((ancestor::Story | ancestor::XmlStory)[last()]//ParagraphStyleRange)[last()] is current()]" 
    mode="idml2xml:SeparateParagraphs"
    priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@* | node() | processing-instruction()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <!-- ParagraphStyleRange that contains a Br below (in its own scope, i.e., not looking further 
       down than to the next contained ParagraphStyleRange): -->
  <xsl:template
    match="ParagraphStyleRange[.//Br[idml2xml:same-scope(., current())]]" 
    mode="idml2xml:SeparateParagraphs"
    priority="3">
    <xsl:sequence select="idml2xml:split-at-br(.)" />
  </xsl:template>

  <!-- Dealing with erroneous inline elements (of the payload XML format; e.g., span or p). The typesetter
       inserted a paragraph break in the layout and forgot to adjust the tagging. -->
  <xsl:template
    match="XMLElement[@MarkupTag = $idml2xml:split-these-elements-if-they-stretch-across-paragraphs][.//Br[idml2xml:same-scope(., current())]]" 
    mode="idml2xml:SeparateParagraphs"
    priority="3">
    <xsl:sequence select="idml2xml:split-at-br(.)" />
  </xsl:template>

  <xsl:function name="idml2xml:split-at-br" as="element(*)+">
    <xsl:param name="elt" as="element(*)" /><!-- typically element(ParagraphStyleRange) -->
    <xsl:variable name="leaves" as="element(*)+">
      <xsl:choose>
        <xsl:when test="$elt/self::ParagraphStyleRange">
          <xsl:sequence select="$elt//*[(name() = $idml2xml:idml-scope-terminal-names) or not(*)][idml2xml:same-scope(., $elt)]" />
        </xsl:when>
        <xsl:when test="$elt/self::XMLElement">
          <xsl:sequence select="$elt//*[(name() = $idml2xml:idml-scope-terminal-names) or not(*)][idml2xml:same-scope(., $elt)]" />
        </xsl:when>
        <xsl:otherwise>
          <idml2xml:error msg="idml2xml:split-at-br in SeparateParagraphs.xsl is only defined for XMLElement or ParagraphStyleRange"/> 
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:for-each-group select="$leaves" group-ending-with="*[self::Br]">
      <xsl:variable name="cg" select="current-group()" />
      <xsl:apply-templates select="$elt" mode="idml2xml:SeparateParagraphs-slice">
        <xsl:with-param name="local-leaves" select="$cg" tunnel="yes"/>
        <xsl:with-param name="local-leaves-ancestors" select="$cg/ancestor::*" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:for-each-group>
  </xsl:function>

  <!-- move CharacterStyleRange down, immediately above Content -->
  <xsl:template match="CharacterStyleRange" mode="idml2xml:SeparateParagraphs-slice">
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="charstylerange" select="." tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="CrossReferenceSource" mode="idml2xml:SeparateParagraphs-slice">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="*" mode="idml2xml:SeparateParagraphs-slice">
    <xsl:param name="local-leaves" as="element(*)*" tunnel="yes"/>
    <xsl:param name="local-leaves-ancestors" as="element(*)*" tunnel="yes"/>
    <xsl:param name="charstylerange" as="element(CharacterStyleRange)?" tunnel="yes"/>
    <xsl:choose>
      <!-- Current element is one of the leaves whose upward-projected tree should be exported: -->
      <xsl:when test="exists(. intersect $local-leaves)">
        <xsl:choose>
          <!-- No content; remove: -->
          <xsl:when test="self::ParagraphStyleRange[not(.//*[name() = ($idml2xml:idml-content-element-names, 'Br')])]" />
          <!-- Nested para, as in a table cell: -->
          <xsl:when test="self::ParagraphStyleRange[*]">
            <xsl:apply-templates select="." mode="idml2xml:SeparateParagraphs" />
          </xsl:when>
          <xsl:when test="self::XMLElement[@MarkupTag = $idml2xml:split-these-elements-if-they-stretch-across-paragraphs]">
            <xsl:apply-templates select="." mode="idml2xml:SeparateParagraphs" />
          </xsl:when>
          <!-- Move a CharacterStyleRange down here, immediately above the rendered content: -->
          <xsl:when test="exists($charstylerange) and name() = ($idml2xml:idml-content-element-names, 'Footnote')">
            <xsl:variable name="new-charstylerange" as="element(CharacterStyleRange)">
              <CharacterStyleRange>
                <xsl:copy-of select="$charstylerange/(@*, Properties)" />
                <xsl:apply-templates select="." mode="idml2xml:SeparateParagraphs" />
              </CharacterStyleRange>
            </xsl:variable>
            <xsl:variable name="parent-is-crossrefsrc" select="$charstylerange/parent::CrossReferenceSource" as="element(CrossReferenceSource)?" />
            <xsl:choose>
              <xsl:when test="exists($parent-is-crossrefsrc)">
                <!-- move an enclosing CrossRefSrc down, too (thereby potentially splitting it – we gotta do this 
                     because they sometimes span para breaks. We can join them later if they're within the same para.): -->
                <CrossReferenceSource>
                  <xsl:copy-of select="$parent-is-crossrefsrc/@*"/>
                  <xsl:sequence select="$new-charstylerange" />
                </CrossReferenceSource>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$new-charstylerange" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <!-- Plain copy: -->
          <xsl:otherwise>
            <xsl:apply-templates select="." mode="idml2xml:SeparateParagraphs"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Haven't reached a leaf yet, reproduce element identically and continue in the same mode: -->
      <xsl:when test="exists(. intersect $local-leaves-ancestors)">
<!--         <c6/> -->
        <xsl:copy>
          <xsl:copy-of select="$local-leaves[self::Br]/../@ParagraphBreakType, @*" />
          <xsl:apply-templates mode="#current" />
        </xsl:copy>
      </xsl:when>
      <xsl:when test="self::XMLAttribute">
        <xsl:sequence select="." />
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
      <!-- No xsl:otherwise: Implicitly discard everything that is not among the common ancestors of our leaves. -->
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="Properties[not(parent::CharacterStyleRange)]" mode="idml2xml:SeparateParagraphs-slice">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- will be dealt with separately, when pulling down cstyleranges -->
  <xsl:template match="CharacterStyleRange/Properties" mode="idml2xml:SeparateParagraphs-slice"/>
  
</xsl:stylesheet>