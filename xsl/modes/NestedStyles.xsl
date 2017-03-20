<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  exclude-result-prefixes="aid xs idml2xml">
  
  <!-- Please note that this mode has side effects. For example, it will split links that contain 
       nested style candidates, or it may put spaces that are at the beginning or end of a span 
       out of that span. -->

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

  <xsl:template mode="idml2xml:NestedStyles-create-separators" match="*[@aid:pstyle]">
    <xsl:variable name="instructions" as="element(ListItem)*" 
      select="key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))[last()]/ListItem"/>
    <xsl:variable name="separator-regex-chars" as="xs:string?"
      select="string-join(for $i in $instructions return idml2xml:NestedStyles-Delimiter-to-regex-chars($i), '')"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="potentially-sep-containing-text-nodes" tunnel="yes" 
          select=".//text()[idml2xml:same-scope(., current())]
                           [not(ancestor::Properties)]
                           [if ($separator-regex-chars) 
                            then matches(., concat('[', $separator-regex-chars, ']'))
                            else false()
                           ]"/>
        <xsl:with-param name="regex" tunnel="yes" 
          select="if ($separator-regex-chars)
                  then concat('[', $separator-regex-chars, ']')
                  else ()"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!-- We don’t (yet) support:
    Sentence AnyCharacter Letters Digits InlineGraphic DropCap EndNestedStyle AutoPageNumber SectionMarker Repeat
    We do support:
    Tabs ForcedLineBreak IndentHereTab EmSpace EnSpace NonbreakingSpace AnyWord
    -->
  
  <xsl:template match="text()" mode="idml2xml:NestedStyles-create-separators">
    <xsl:param name="potentially-sep-containing-text-nodes" as="text()*" tunnel="yes"/>
    <xsl:param name="regex" as="xs:string?" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$regex and
                      (some $t in $potentially-sep-containing-text-nodes satisfies ($t is .))">
        <xsl:variable name="context" select="." as="text()"/>
        <xsl:analyze-string select="." regex="{$regex}">
          <xsl:matching-substring>
            <!-- Record ancestors that are not plain character style ranges so that we can report them later 
                 if they are split at this separator’s position: -->
            <idml2xml:sep ancestors="{$context/(ancestor::* intersect ancestor::*[@aid:pstyle][1]/descendant::*)
                                                  [not(self::idml2xml:genSpan[not(@AppliedConditions)])]/name()}">
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
                        [key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))]"
                        mode="idml2xml:NestedStyles-pull-up-separators">
    <xsl:variable name="context" select="." as="element(*)" />
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of select="@*"/>
      <xsl:for-each-group
        select="descendant::node()
                                  [
                                    (idml2xml:is-scope-terminal(.))
                                    or 
                                    not(node())
                                  ][idml2xml:same-scope(., current())]"
        group-starting-with="*[idml2xml:is-pull-up-separator(.)]">
        <xsl:copy-of select="current-group()/(self::*[idml2xml:is-pull-up-separator(.)])"/>
        <xsl:apply-templates select="$context/node()" mode="idml2xml:NestedStyles-upward-project">
          <xsl:with-param name="restricted-to" 
            select="current-group()/ancestor-or-self::node()[not(self::*[idml2xml:is-pull-up-separator(.)])]" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:for-each-group>  
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="idml2xml:is-pull-up-separator" as="xs:boolean">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="(
                            $el/self::idml2xml:tab
                            or
                            $el/self::idml2xml:sep
                          )
                          and 
                          not($el/self::idml2xml:tab[@role]
                                 /parent::idml2xml:genSpan[
                                   every $n in node() 
                                   satisfies $n[self::idml2xml:tab[@role] or self::Properties]
                                 ]
                          )"/>
  </xsl:function>

  <xsl:template match="node()" mode="idml2xml:NestedStyles-upward-project">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:copy copy-namespaces="no">
        <xsl:copy-of select="@*" />
        <xsl:apply-templates mode="#current" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[idml2xml:is-scope-terminal(.)]/*" mode="idml2xml:NestedStyles-upward-project">
    <xsl:apply-templates select="." mode="idml2xml:NestedStyles-pull-up-separators"/>
  </xsl:template>

  <!-- Deal with tables, footnotes etc. that are contained in the para or its spans -->
  <xsl:template match="*[idml2xml:is-scope-terminal(.)]" mode="idml2xml:NestedStyles-upward-project"
    priority="-0.75">
    <xsl:apply-templates select="." mode="idml2xml:NestedStyles-pull-up-separators" />
  </xsl:template>


  <!-- MODE: idml2xml:NestedStyles-apply -->
  <!-- Wrap stretches of text with character styles spans according to the nested style instructions. -->
  
  <xsl:template match="*[@aid:pstyle]
                        [key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))]"
                mode="idml2xml:NestedStyles-apply">
    <xsl:variable name="instructions" as="element(ListItem)+" 
      select="key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))[last()]/ListItem"/>
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
        <xsl:variable name="pre-split-cstyle" as="xs:string" select="idml2xml:StyleName($instructions[1]/AppliedCharacterStyle)"/>
        <xsl:variable name="pre-split-transformed" as="node()*">
          <xsl:apply-templates select="if ($splitting-point) 
                                       then $nodes[. &lt;&lt; $splitting-point] 
                                       else $nodes"
            mode="idml2xml:NestedStyles-apply">
            <xsl:with-param name="pre-split-cstyle" select="$pre-split-cstyle"/>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="every $n in $pre-split-transformed[normalize-space()] 
                          satisfies ($n/@aid:cstyle = $pre-split-cstyle)">
            <!-- The to-be-applied cstyle is already present or whitespace-only nodes, cf. UV 00495_Singh_Nekropolis,
                 Stories/Story_u17d.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[285]/CharacterStyleRange[5] -->
            <xsl:sequence select="$pre-split-transformed"/>
          </xsl:when>
          <xsl:otherwise>
            <idml2xml:genSpan aid:cstyle="{$pre-split-cstyle}">
              <xsl:sequence select="$pre-split-transformed"/>
            </idml2xml:genSpan>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="$splitting-point" mode="idml2xml:NestedStyles-apply"/>
        <xsl:if test="$splitting-point/@ancestors != ''">
          <xsl:message>NestedStyles: Separator after '<xsl:value-of select="$nodes[. &lt;&lt; $splitting-point]"/>' 
  has split the following elements: <xsl:value-of select="$splitting-point/@ancestors"/>. Please check.</xsl:message>
        </xsl:if>
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
  
  <xsl:template match="*[@aid:cstyle][not(normalize-space())]" mode="idml2xml:NestedStyles-apply">
    <xsl:param name="pre-split-cstyle" as="xs:string?"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$pre-split-cstyle">
        <xsl:attribute name="aid:cstyle" select="$pre-split-cstyle"/>  
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="idml2xml:tab[@role eq 'end-nested-style']" mode="idml2xml:NestedStyles-apply" />

  <xsl:function name="idml2xml:NestedStyles-Delimiter-to-regex-chars" as="xs:string?">
    <xsl:param name="instruction" as="element(ListItem)"/>
    <xsl:choose>
      <xsl:when test="$instruction/Delimiter = 'EnSpace'">
        <xsl:sequence select="'&#x2002;'"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'EmSpace'">
        <xsl:sequence select="'&#x2003;'"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'ForcedLineBreak'">
        <xsl:sequence select="'&#x2028;'"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'NonbreakingSpace'">
        <xsl:sequence select="'&#xa0;&#x202f;'"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'AnyWord'">
        <xsl:sequence select="'\p{Zs}'"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="idml2xml:NestedStyles-splitting-point-candidates" as="element(*)*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="instruction" as="element(ListItem)"/>
    <xsl:choose>
      <xsl:when test="$instruction/Delimiter = ('EnSpace', 'EmSpace', 'ForcedLineBreak', 'NonbreakingSpace')">
        <xsl:sequence 
          select="$nodes/self::idml2xml:sep[matches(., concat('^[', idml2xml:NestedStyles-Delimiter-to-regex-chars($instruction), ']$'))]"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'EndNestedStyle'">
        <xsl:sequence select="$nodes/self::idml2xml:tab[@role eq 'end-nested-style']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'Tabs'">
        <xsl:sequence select="$nodes/self::idml2xml:tab"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'IndentHereTab'">
        <xsl:sequence select="$nodes/self::idml2xml:tab[@ole = 'indent-to-here']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'AnyWord'">
        <xsl:sequence select="$nodes/(self::idml2xml:sep | self::idml2xml:tab)
          [not(preceding-sibling::node()[1]/(self::idml2xml:sep | self::idml2xml:tab))]"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>