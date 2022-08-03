<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  xmlns:functx="http://www.functx.com"
  exclude-result-prefixes="aid xs idml2xml functx">
  
  <xsl:include href="http://transpect.io/xslt-util/functx/Strings/Replacing/escape-for-regex.xsl"/>
  <xsl:import href="JoinSpans.xsl"/>
  
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

  <xsl:function name="idml2xml:dropcap-regex" as="xs:string">
    <xsl:param name="count" as="xs:integer"/>
    <xsl:sequence select="concat('^(\S{', $count, '})(.*)$')"/>
  </xsl:function>

  <xsl:template mode="idml2xml:NestedStyles-create-separators" match="*[@aid:pstyle]">
    <xsl:variable name="nested-style-cascade" as="element(*)*" 
      select="key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))"/>
    <xsl:variable name="instructions" as="element(ListItem)*" 
      select="($nested-style-cascade)[ListItem][last()]/ListItem"/>
    <xsl:variable name="separator-regex-chars" as="xs:string?"
      select="string-join(for $i in $instructions return idml2xml:NestedStyles-Delimiter-to-regex-chars($i), '')"/>
    <xsl:variable name="style-cascade" as="element(*)*" 
      select="for $s in key('idml2xml:by-Self', concat('ParagraphStyle/', @aid:pstyle)) 
              return idml2xml:style-ancestors-and-self($s)"/>
    <xsl:variable name="dropcap-regex" as="xs:string?" 
      select="for $d in (/idml2xml:doc/*:Preferences/TextDefault/@DropCapCharacters,
                         $style-cascade/@DropCapCharacters)[last()][. > 0] 
              return idml2xml:dropcap-regex(xs:integer($d))"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$instructions[1]/Delimiter = 'Dropcap' and empty($dropcap-regex)">
        <xsl:attribute name="idml2xml:dropcaps" select="'none'"/>
      </xsl:if>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="potentially-sep-containing-text-nodes" tunnel="yes" as="text()*">
          <xsl:choose>
            <xsl:when test="$separator-regex-chars">
              <xsl:sequence 
                select=".//text()[idml2xml:same-scope(., current())]
                                 [not(ancestor::Properties)]
                                 [not(ancestor::idml2xml:link)](: https://redmine.le-tex.de/issues/5782#note-43 :)
                                 [matches(., concat('[', $separator-regex-chars, ']'))]"/>
            </xsl:when>
            <xsl:when test="$instructions[1]/Delimiter = 'Dropcap' and exists($dropcap-regex)">
              <xsl:sequence 
                select="(.//text()[idml2xml:same-scope(., current())]
                                  [not(ancestor::Properties)]
                                  [not(ancestor::idml2xml:link)]
                                  [matches(., $dropcap-regex)])[1]"/>
            </xsl:when>
          </xsl:choose>
        </xsl:with-param> 
        <xsl:with-param name="regex" tunnel="yes" as="xs:string?" 
          select="if ($separator-regex-chars)
                  then concat('[', $separator-regex-chars, ']')
                  else if ($instructions[1]/Delimiter = 'Dropcap')
                       then $dropcap-regex
                       else ()"/>
        <xsl:with-param name="instruction" as="element(ListItem)?" select="$instructions[1]" tunnel="yes"/>
        <xsl:with-param name="regex-type" as="xs:string?" select="if ($separator-regex-chars)
                                                                 then 'sep'
                                                                 else if ($instructions[1]/Delimiter = 'Dropcap')
                                                                       then 'dropcap'
                                                                       else ()" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!-- We don’t (yet) support:
    Sentence AnyCharacter Letters Digits InlineGraphic EndNestedStyle AutoPageNumber SectionMarker Repeat
    We do support:
    Tabs ForcedLineBreak IndentHereTab EmSpace EnSpace NonbreakingSpace AnyWord DropCap 
    -->
  
  <xsl:template match="text()" mode="idml2xml:NestedStyles-create-separators">
    <xsl:param name="potentially-sep-containing-text-nodes" as="text()*" tunnel="yes"/>
    <xsl:param name="regex" as="xs:string?" tunnel="yes"/>
    <xsl:param name="instruction" as="element(ListItem)?" tunnel="yes"/>
    <xsl:param name="regex-type" as="xs:string?" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$regex and $regex-type eq 'dropcap'
                      and ($instruction/Delimiter = 'Dropcap')
                      and (some $t in $potentially-sep-containing-text-nodes satisfies ($t is .))">
        <xsl:value-of select="replace(., $regex, '$1')"/>
        <idml2xml:sep role="Dropcap"/>
        <xsl:value-of select="replace(., $regex, '$2')"/>
      </xsl:when>
      <xsl:when test="$regex and
                      (some $t in $potentially-sep-containing-text-nodes satisfies ($t is .))">
        <xsl:variable name="context" select="." as="text()"/>
        <xsl:analyze-string select="." regex="{$regex}">
          <xsl:matching-substring>
            <!-- Record ancestors that are not plain character style ranges so that we can report them later 
                 if they are split at this separator’s position: -->
            <idml2xml:sep ancestors="{$context/(ancestor::* intersect ancestor::*[@aid:pstyle][1]/descendant::*)
                                                  [not(self::idml2xml:genSpan[not(@AppliedConditions[normalize-space()])])]/name()}">
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
                        [key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))]
                        [key('idml2xml:by-Self', concat('ParagraphStyle/', @aid:pstyle))[not(@EmptyNestedStyles='true')]]"
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
        group-starting-with="*[idml2xml:is-pull-up-separator(., $context)]">
        <xsl:copy-of select="current-group()/(self::*[idml2xml:is-pull-up-separator(., $context)])"/>
        <xsl:apply-templates select="$context/node()" mode="idml2xml:NestedStyles-upward-project">
          <xsl:with-param name="restricted-to" 
                          select="current-group()/ancestor-or-self::node()[not(self::*[idml2xml:is-pull-up-separator(., $context)])]" tunnel="yes"/>
          <xsl:with-param name="pos" select="position()" as="xs:integer" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:for-each-group>  
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="idml2xml:is-pull-up-separator" as="xs:boolean">
    <xsl:param name="el" as="element()"/>
    <xsl:param name="context-para" as="element()"/>
    <xsl:variable name="nested-style-cascade" as="element(*)*" 
      select="$context-para/key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))"/>
    <xsl:variable name="instructions" as="element(ListItem)*" 
      select="($nested-style-cascade)[ListItem][last()]/ListItem"/>
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
                          )
                          (:do not pull up separators that extend beyond defined Repetition:)
                          and count($el/preceding::*[name() = ('idml2xml:tab', 'idml2xml:sep')]
                                                    [not(self::idml2xml:tab[@role]
                                                      /parent::idml2xml:genSpan[
                                                                                every $n in node() 
                                                                                satisfies $n[self::idml2xml:tab[@role] or self::Properties]
                                                                                ]
                                                      )]
                                                     [ancestor::idml2xml:genPara[1] is $context-para]
                                    ) &lt; xs:integer(number($instructions[1]/Repetition))"/>
  </xsl:function>

  <xsl:template match="node()" mode="idml2xml:NestedStyles-upward-project">
    <xsl:param name="restricted-to" as="node()+" tunnel="yes" />
    <xsl:param name="pos" select="1" as="xs:integer" tunnel="yes"/>
    <xsl:if test="exists(. intersect $restricted-to)">
      <xsl:copy copy-namespaces="no">
        <!-- https://redmine.le-tex.de/issues/13079 
             do not duplicate srcpaths to avoid duplicate element errors later -->
        <xsl:copy-of select="if($pos gt 1) 
                             then @* except @srcpath
                             else @*"/>
        <xsl:if test="$pos gt 1">
          <xsl:attribute name="srcpath" select="concat(@srcpath, '_', $pos)"/>
        </xsl:if>
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
                        [key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))]
                        [key('idml2xml:by-Self', concat('ParagraphStyle/', @aid:pstyle))[not(@EmptyNestedStyles='true')]]"
                mode="idml2xml:NestedStyles-apply">
    <!-- We are not using the last nested styles of sequence that is returned by idml2xml:nested-style because its order has been found to be off.
        (see https://subversion.le-tex.de/customers/aufbau/content/aufbau/AV/9783841229694_01)
        Instead, we'll use the most specific instruction from idml2xml:style-ancestors-and-self -->
    <xsl:variable name="instructions" as="element(ListItem)+" 
      select="idml2xml:style-ancestors-and-self(key('idml2xml:by-Self', concat('ParagraphStyle/', @aid:pstyle)))[descendant::AllNestedStyles][1]/Properties/AllNestedStyles/ListItem"/>
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of select="@* except @idml2xml:dropcaps, Properties"/>
      <xsl:sequence select="idml2xml:apply-nested-style(node() except Properties, $instructions, @idml2xml:dropcaps)"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:function name="idml2xml:apply-nested-style" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="instructions" as="element(ListItem)*"/>
    <xsl:param name="dropcaps-flag" as="attribute(idml2xml:dropcaps)?"/>
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
            <xsl:with-param name="pre-split-cstyle" select="$pre-split-cstyle" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="every $n in $pre-split-transformed[normalize-space()][not(self::idml2xml:genFrame)] 
                          satisfies ($n/@aid:cstyle = $pre-split-cstyle)">
            <!-- The to-be-applied cstyle is already present or whitespace-only nodes, cf. UV 00495_Singh_Nekropolis,
                 Stories/Story_u17d.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[285]/CharacterStyleRange[5]
            idml2xml:genFrame: UV 39001 Story_u3dc.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[489]/CharacterStyleRange[2]-->
            <xsl:sequence select="$pre-split-transformed"/>
          </xsl:when>
          <xsl:when test="$dropcaps-flag = 'none'">
            <xsl:sequence select="$pre-split-transformed"/>
          </xsl:when>
          <xsl:otherwise>
            <idml2xml:genSpan aid:cstyle="{$pre-split-cstyle}">
              <xsl:sequence select="$pre-split-transformed"/>
              <xsl:if test="$instructions[1]/Inclusive = 'true' and not($instructions[1]/Delimiter = 'AnyWord')">
                <xsl:apply-templates select="$splitting-point" mode="idml2xml:NestedStyles-apply"/>
              </xsl:if>
            </idml2xml:genSpan>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$instructions[1]/Inclusive = 'false' or $instructions[1]/Delimiter = 'AnyWord'">
          <xsl:apply-templates select="$splitting-point" mode="idml2xml:NestedStyles-apply"/>
        </xsl:if>
        <xsl:if test="$splitting-point/@ancestors != ''">
          <xsl:message>NestedStyles: Separator after '<xsl:value-of select="$nodes[. &lt;&lt; $splitting-point]"/>' 
  has split the following elements: <xsl:value-of select="$splitting-point/@ancestors"/>. Please check.</xsl:message>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="exists($instructions[2])">
            <xsl:sequence
              select="idml2xml:apply-nested-style($splitting-point/following-sibling::node(), 
                                                  $instructions[position() gt 1], 
                                                  $dropcaps-flag)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="$splitting-point/following-sibling::node()" mode="idml2xml:NestedStyles-apply"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="pre-split-cstyle" as="xs:string?" 
          select="for $s in $instructions[1]/AppliedCharacterStyle return idml2xml:StyleName($s)"/>
        <xsl:variable name="pre-split-transformed" as="node()*">
          <xsl:apply-templates select="$nodes" mode="idml2xml:NestedStyles-apply">
            <!-- This is for applying the next style in the list to extents /after/ the splitting point, 
              see https://redmine.le-tex.de/issues/6677 
            This part of the solution has not been tested thoroughly-->
            <xsl:with-param name="pre-split-cstyle" as="xs:string?" select="$pre-split-cstyle"/>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="every $n in $pre-split-transformed[normalize-space()] 
                          satisfies ($n/@aid:cstyle = $pre-split-cstyle)">
            <!-- The to-be-applied cstyle is already present or whitespace-only nodes, cf. UV 00495_Singh_Nekropolis,
                 Stories/Story_u17d.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[285]/CharacterStyleRange[5] -->
            <xsl:sequence select="$pre-split-transformed"/>
          </xsl:when>
          <xsl:when test="$instructions[1]/Delimiter = ('AnyCharacter', 'Letters', 'Digits', 'InlineGraphic', 
                                                        'EndNestedStyle', 'AutoPageNumber', 'SectionMarker', 'Repeat')">
            <!-- not implemented yet -->
            <xsl:sequence select="$pre-split-transformed"/>
          </xsl:when>
          <xsl:when test="$dropcaps-flag = 'none'">
            <xsl:sequence select="$pre-split-transformed"/>
          </xsl:when>
            <xsl:when test="exists($pre-split-cstyle)
                          and empty($pre-split-transformed[normalize-space()][@aid:cstyle = $pre-split-cstyle])
                          and exists($pre-split-transformed[normalize-space()])">
            <!-- the latter is an ad-hoc condition for UV 39002, Story_u3e45.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[76] -->
            <idml2xml:genSpan aid:cstyle="{$pre-split-cstyle}">
              <xsl:sequence select="$pre-split-transformed"/>
            </idml2xml:genSpan>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$pre-split-transformed"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="idml2xml:sep" mode="idml2xml:NestedStyles-apply">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="*[@aid:cstyle][not(normalize-space())]" mode="idml2xml:NestedStyles-apply">
    <xsl:param name="pre-split-cstyle" as="xs:string?" tunnel="yes"/>
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
        <!-- Problem was here: 00a0, 200a and 202f still count as the same word. so \p{Zs} was replaced by single space characters -->
        <xsl:sequence select="'&#x20;&#x2001;&#x2002;&#x2003;&#x2004;&#x2005;&#x2006;&#x2007;&#x2008;&#x2009;'"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter/@type = 'string'">
        <xsl:sequence select="functx:escape-for-regex($instruction/Delimiter)"/>
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
      <xsl:when test="$instruction/Delimiter = ('Dropcap')">
        <xsl:sequence 
          select="$nodes/self::idml2xml:sep[@role = 'Dropcap']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'EndNestedStyle'">
        <xsl:sequence select="$nodes/self::idml2xml:tab[@role eq 'end-nested-style']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'Tabs'">
        <xsl:sequence select="$nodes/self::idml2xml:tab"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'IndentHereTab'">
        <xsl:sequence select="$nodes/self::idml2xml:tab[@role = 'indent-to-here']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = '^y'">
        <xsl:sequence select="$nodes/self::idml2xml:tab[@role = 'right']"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'AnyWord'">
        <xsl:sequence select="$nodes/(self::idml2xml:sep | self::idml2xml:tab)
          [not(preceding-sibling::node()[1]/(self::idml2xml:sep | self::idml2xml:tab))]"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter/@type = 'string'">
        <xsl:sequence select="$nodes/self::idml2xml:sep[matches(., concat('^[', idml2xml:NestedStyles-Delimiter-to-regex-chars($instruction), ']$'))]"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="*[@aid:pstyle]
    [key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))]
    [key('idml2xml:by-Self', concat('ParagraphStyle/', @aid:pstyle))[not(@EmptyNestedStyles='true')]]"
    mode="idml2xml:NestedStyles-join">    
    <xsl:apply-templates mode="idml2xml:JoinSpans"/>
  </xsl:template>
  
  <xsl:template match="* | @* | comment() | processing-instruction()" priority="-1"
    mode="idml2xml:NestedStyles-join">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="idml2xml:JoinSpans"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>