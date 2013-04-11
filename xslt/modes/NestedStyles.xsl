<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  exclude-result-prefixes="aid xs idml2xml">

  <xsl:key name="idml2xml:nested-style" match="AllNestedStyles" 
    use="idml2xml:style-descendants-and-self(../..)/@Self"/>
  <!-- When using this key, it is important to know that it will also return AllNestedStyles
       for the styles that the style in question is based upon. This is because the nested
       styles are not necessarily attached to the current paragraph style. They might as well
       be declared for a style that the current one is based upon, or on one of their ancestor
       styles. We are (safely?) assuming that derivative styles will always be serialized 
       after their base styles. So use the last() item of the sequence that the key() function 
       returns. This is the most specific one. If this document order / specificity assumption  
       proves to be unwarranted, we’d have to evaluate the inheritance cascade more thoroughly. 
  -->

  <!-- MODE: idml2xml:NestedStyles-create-separators 
        Make idml2xml:sep elements of the letters that may act as nested style separators -->

  <xsl:template mode="idml2xml:NestedStyles-create-separators"
    match="*[@aid:pstyle]
            [key('idml2xml:nested-style', concat('ParagraphStyle/', idml2xml:StyleNameEscape(@aid:pstyle)))]">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="potentially-sep-containing-text-nodes" tunnel="yes" 
          select=".//text()[idml2xml:same-scope(., current())]"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!-- We don’t (yet) support:
    Sentence AnyCharacter Letters Digits InlineGraphic DropCap EndNestedStyle AutoPageNumber SectionMarker Repeat
    We do support:
    Tabs ForcedLineBreak IndentHereTab EmSpace EnSpace NonbreakingSpace AnyWord
    -->
  <xsl:variable name="idml2xml:NestedStyles-separator-regex" as="xs:string"
    select="'[\p{Zs}&#x2028;]'"/>
  
  <xsl:template match="text()" mode="idml2xml:NestedStyles-create-separators">
    <xsl:param name="potentially-sep-containing-text-nodes" as="text()*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="some $t in $potentially-sep-containing-text-nodes satisfies ($t is .)">
        <xsl:analyze-string select="." regex="{$idml2xml:NestedStyles-separator-regex}">
          <xsl:matching-substring>
            <idml2xml:sep>
              <xsl:sequence select="."/>
            </idml2xml:sep>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:sequence select="."/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- MODE: idml2xml:NestedStyles-pull-up-separators -->
  <!-- The separators that have been created in the previous mode (and idml2xml:tab elements)
       will be extracted from their spans (if they are surrounded by spans) and placed 
       immediately below the paragraph element, effectively splitting the spans. -->
  
  <xsl:template match="*[@aid:pstyle]
                        [key('idml2xml:nested-style', concat('ParagraphStyle/', idml2xml:StyleNameEscape(@aid:pstyle)))]"
                        mode="idml2xml:NestedStyles-pull-up-separators">
    <xsl:variable name="context" select="." as="element(*)" />
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of select="@*"/>
      <xsl:for-each-group
        select="descendant::node()
                                  [
                                    (name() = $idml2xml:idml-scope-terminal-names)
                                    or 
                                    not(node())
                                  ][idml2xml:same-scope(., current())]"
        group-starting-with="idml2xml:tab | idml2xml:sep">
        <xsl:copy-of select="current-group()/(self::idml2xml:tab | self::idml2xml:sep)"/>
        <xsl:apply-templates select="$context/node()" mode="idml2xml:NestedStyles-upward-project">
          <xsl:with-param name="restricted-to" 
            select="current-group()/ancestor-or-self::node()[not(self::idml2xml:tab or self::idml2xml:sep)]" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:for-each-group>  
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()" mode="idml2xml:NestedStyles-upward-project">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:copy copy-namespaces="no">
        <xsl:copy-of select="@*" />
        <xsl:apply-templates mode="#current" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[name() = $idml2xml:idml-scope-terminal-names]/*" mode="idml2xml:NestedStyles-upward-project">
    <xsl:apply-templates select="." mode="idml2xml:NestedStyles-pull-up-separators"/>
  </xsl:template>

  <!-- Deal with tables, footnotes etc. that are contained in the para or its spans -->
  <xsl:template match="*[name() = $idml2xml:idml-scope-terminal-names]" mode="idml2xml:NestedStyles-upward-project"
    priority="-0.75">
    <xsl:apply-templates select="." mode="idml2xml:NestedStyles-pull-up-separators" />
  </xsl:template>


  <!-- MODE: idml2xml:NestedStyles-apply -->
  <!-- Wrap stretches of text with character styles spans according to the nested style instructions. -->
  
  <xsl:template match="*[@aid:pstyle]
    [key('idml2xml:nested-style', concat('ParagraphStyle/', idml2xml:StyleNameEscape(@aid:pstyle)))]"
    mode="idml2xml:NestedStyles-apply">
    <xsl:variable name="instructions" as="element(ListItem)+" 
      select="key('idml2xml:nested-style', concat('ParagraphStyle/', idml2xml:StyleNameEscape(@aid:pstyle)))[last()]/ListItem"/>
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of select="@*, Properties"/>
      <xsl:sequence select="idml2xml:apply-nested-style(node() except Properties, $instructions)"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:function name="idml2xml:apply-nested-style" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="instructions" as="element(ListItem)*"/>
    <xsl:variable name="splitting-point-candidates" as="element(*)*" 
      select="idml2xml:NestedStyles-splitting-point-candidates($nodes, $instructions[1])"/>
    <!--<cands>
      <xsl:sequence select="$splitting-point-candidates, $instructions[1], $nodes"/>
    </cands>-->
    <xsl:variable name="splitting-point" as="element(*)?" 
      select="$splitting-point-candidates[position() = xs:integer(number($instructions[1]/Repetition))]"/>
    <xsl:choose>
      <xsl:when test="exists($splitting-point)">
        <idml2xml:genSpan aid:cstyle="{idml2xml:StyleName($instructions[1]/AppliedCharacterStyle)}">
          <xsl:apply-templates select="if ($splitting-point) 
                                       then $nodes[. &lt;&lt; $splitting-point] 
                                       else $nodes"
            mode="idml2xml:NestedStyles-apply"/>
        </idml2xml:genSpan>
        <xsl:apply-templates select="$splitting-point" mode="idml2xml:NestedStyles-apply"/>
        <xsl:choose>
          <xsl:when test="exists($instructions[2])">
            <xsl:sequence
              select="idml2xml:apply-nested-style($splitting-point/following-sibling::node(), $instructions[position() gt 1])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="$splitting-point/following-sibling::node()" mode="idml2xml:NestedStyles-apply"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$nodes" mode="idml2xml:NestedStyles-apply"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="idml2xml:sep" mode="idml2xml:NestedStyles-apply">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:function name="idml2xml:NestedStyles-splitting-point-candidates" as="element(*)*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="instruction" as="element(ListItem)"/>
    <xsl:choose>
      <xsl:when test="$instruction/Delimiter = 'EnSpace'">
        <xsl:sequence select="$nodes/self::idml2xml:sep[. = '&#x2002;']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'EmSpace'">
        <xsl:sequence select="$nodes/self::idml2xml:sep[. = '&#x2003;']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'Tabs'">
        <xsl:sequence select="$nodes/self::idml2xml:tab"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'IndentHereTab'">
        <xsl:sequence select="$nodes/self::idml2xml:tab[@ole = 'indent-to-here']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'ForcedLineBreak'">
        <xsl:sequence select="$nodes/self::idml2xml:sep[. = '&#x2028;']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'NonbreakingSpace'">
        <xsl:sequence select="$nodes/self::idml2xml:sep[. = ('&#xa0;', '&#x202f;')]"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'AnyWord'">
        <xsl:sequence select="$nodes/(self::idml2xml:sep | self::idml2xml:tab)
          [not(preceding-sibling::node()[1]/(self::idml2xml:sep | self::idml2xml:tab))]"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>