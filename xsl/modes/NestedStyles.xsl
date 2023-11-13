<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="3.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  xmlns:functx="http://www.functx.com"
  xmlns:map = "http://www.w3.org/2005/xpath-functions/map"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:dbk = "http://docbook.org/ns/docbook"
  exclude-result-prefixes="aid css dbk xs idml2xml functx map">
  
  <xsl:include href="http://transpect.io/xslt-util/functx/Strings/Replacing/escape-for-regex.xsl"/>
  <xsl:param name="nested-styles-debugging-srcpath" as="xs:string" select="'nothing-matches'">
    <!-- for test_after/hogrefe.ch/GWFB/85875 for example: 
      'Stories/Story_u51f.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[19]'
      'Stories/Story_u51f.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[85]/CharacterStyleRange[6]/Footnote[1]/ParagraphStyleRange[1]'
    -->
  </xsl:param>


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
    <xsl:sequence select="concat('^(\S{', $count, '})')"/>
  </xsl:function>

  <!-- We don’t (yet) support:
    Sentence AnyCharacter Digits InlineGraphic EndNestedStyle(?) AutoPageNumber SectionMarker Repeat
    We do support:
    Tabs ForcedLineBreak IndentHereTab EmSpace EnSpace NonbreakingSpace AnyWord Letters DropCap string
    -->
  
  <xsl:mode name="idml2xml:NestedStyles-create-separators" use-accumulators="#all"/>
  
  <!-- nested-style-instruction:
    Sequence of maps. The map for the current para comes first, the map of the containing para, if there is any, comes second, etc.
    An individual map has the following keys:
    'instruction':          The current instruction, AllNestedStyles/ListItem. At the beginning of a para,
                            it is the first instruction. At the beginning of a text node, it might be an
                            instruction that has already been fully applied in previous nodes;
    'text-consumed':        The text that has been consumed in previous text nodes by the current instruction;
    'loop-count':           See https://helpx.adobe.com/indesign/using/drop-caps-nested-styles.html#loop_through_nested_styles
                            An xs:integer value that holds the current loop number, starting with 1. 
                            This kind of repetition has not been implemented yet. 
    'future-separators':    A sequence of maps, one map for each separator to be inserted into the current text node, 
                            with an xs:integer key – the string position after which the separator needs to be inserted;
                            and an element(ListItem) value – the instruction that will be used to create the separator.
                            The key -1 signals that the associated instruction is still active and hasn’t yet 
                            inserted a separator in previous text nodes.
    The accumulator primarily applies to text nodes that are part of a paragraph. Footnotes or table cells that are contained
    in a paragraph will push a new map ahead of the current sequence of maps. At the end of the contained para this
    map will be popped from the sequence so that the processing of the containing para may continue.
    -->
  <xsl:accumulator name="nested-style-instruction" initial-value="()" as="map(xs:string, item()*)*">
    <xsl:accumulator-rule match="*[@aid:pstyle]" phase="start">
      <xsl:variable name="nested-style-cascade" as="element(*)*" 
        select="key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))"/>
      <xsl:variable name="instruction-list" as="element(AllNestedStyles)?" 
        select="($nested-style-cascade)[ListItem][last()]"/>
      <xsl:sequence select="(map{'instruction': $instruction-list/ListItem[1], 
                                 'text-consumed': '', 
                                 'future-separators': (),
                                 'loop-count': 1}, 
                             $value)"/>
    </xsl:accumulator-rule>
    
    <xsl:accumulator-rule match="*[@aid:pstyle]" phase="end">
      <xsl:sequence select="tail($value)"/>
    </xsl:accumulator-rule>
    
    
    <xsl:accumulator-rule match="*[@aid:pstyle]//text()[idml2xml:is-para-text(., ancestor::*[@aid:pstyle][1])]" 
      phase="start">
      <xsl:sequence select="$value"/>
    </xsl:accumulator-rule>
    
    <xsl:accumulator-rule match="*[@aid:pstyle]//text()[idml2xml:is-para-text(., ancestor::*[@aid:pstyle][1])]" 
      phase="end">
      <xsl:variable name="initial-instruction" as="element(ListItem)?" 
        select="if ($value[1]?instruction instance of map(*))
                then $value[1]?instruction ! map:keys(.) ! map:get($value[1]?instruction, .)
                else $value[1]?instruction">
        <!-- There was a bug (probably in Saxon including 10.6 and 12.3) that put a map(xs:integer, element(ListItem)) here
          instead of element(ListItem). That is, a future separator took the instruction’s place -->
      </xsl:variable>
      <xsl:variable name="initial-text-consumed" as="xs:string?" select="$value[1]?text-consumed">
        <!-- text consumed by the current instruction in previous nodes; that is, the first part of the string 
             that the current instruction will process when trying to insert its separators into the current text node. -->
      </xsl:variable>
      <xsl:variable name="compound-text" as="xs:string" 
        select="$initial-text-consumed || string(.)"/>
      <xsl:variable name="this-node" as="text()" select="."/>
      <xsl:variable name="saved-value" as="map(xs:string, item()*)*" select="$value">
        <!-- There was another Saxon bug that replaced $value with the current text -->
      </xsl:variable>
      <xsl:variable name="this-node-future-separators" as="map(xs:integer, element(ListItem))*">
        <xsl:sequence select="idml2xml:NestedStyle-separator-maps(
                                $initial-instruction/(., following-sibling::ListItem),
                                $compound-text,
                                .,
                                ()
                              )"/>
      </xsl:variable>
      <xsl:variable name="last-new-sep" as="map(xs:integer, element(ListItem))?" select="$this-node-future-separators[last()]"/>
      <xsl:variable name="last-new-sep-pos" as="xs:integer?" select="($last-new-sep ! map:keys(.))[last()]"/>
      <xsl:variable name="substring-length" as="xs:integer" 
        select="if ($last-new-sep-pos) 
                then string-length($this-node) - $last-new-sep-pos + 1
                else string-length($this-node)"/>
      <xsl:variable name="new-maps" as="map(xs:string, item()*)+"
        select="(map{'instruction': if ($last-new-sep-pos)
                                    then $last-new-sep($last-new-sep-pos)/following-sibling::*[1] 
                                    else $initial-instruction,
                     'text-consumed': if (exists($last-new-sep-pos) and ($last-new-sep-pos ge 0)) 
                                      then substring($this-node, $last-new-sep-pos + 1)
                                      else $initial-text-consumed || $this-node, 
                     'future-separators': $this-node-future-separators}, 
                 tail($saved-value))"/>
      <xsl:sequence select="$new-maps"/>
    </xsl:accumulator-rule>
  </xsl:accumulator>
  
  <xsl:function name="idml2xml:NestedStyle-separator-maps" as="map(xs:integer, element(ListItem))*">
    <!-- ran into a Saxon bug when trying to implement it using xsl:iterate -->
    <xsl:param name="instructions" as="element(ListItem)*"/>
    <xsl:param name="input-text" as="xs:string"/>
    <xsl:param name="current-text-node" as="text()"/>
    <xsl:param name="future-separators-so-far" as="map(xs:integer, element(ListItem))*"/>
    <xsl:choose>
      <xsl:when test="empty($instructions)">
        <xsl:sequence select="$future-separators-so-far"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="this-iteration-future-separator" as="map(xs:integer, element(ListItem))?">
          <xsl:apply-templates select="$instructions[1]" mode="idml2xml:apply-nested-style-instruction">
            <xsl:with-param name="string" as="xs:string" select="$input-text" tunnel="yes"/>
            <xsl:with-param name="text-node" as="text()" select="$current-text-node" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:if test="contains($current-text-node/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
          <xsl:message select="'&#xa;FFFFFFF', string-length($input-text), '+++', $input-text, '+++', 
            $current-text-node, '  ',empty($this-iteration-future-separator),(: $instructions[1],:)
            serialize($this-iteration-future-separator, map{'method': 'adaptive'})"></xsl:message>
        </xsl:if>
        <xsl:variable name="this-iteration-pos" as="xs:integer?"
          select="$this-iteration-future-separator ! map:keys(.)"/>
        <xsl:choose>
          <xsl:when test="empty($this-iteration-future-separator)">
            <xsl:sequence select="$future-separators-so-far"/>
          </xsl:when>
          <xsl:when test="$this-iteration-pos = string-length($current-text-node)">
            <xsl:sequence select="$future-separators-so-far, $this-iteration-future-separator"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="idml2xml:NestedStyle-separator-maps(
                                    tail($instructions),
                                    if ($this-iteration-pos instance of xs:integer)
                                    then substring($current-text-node, $this-iteration-pos + 1)
                                    else $current-text-node,
                                    $current-text-node,
                                    ($future-separators-so-far, $this-iteration-future-separator)
                                  )"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="idml2xml:future-separators-for-instruction" as="map(xs:integer, element(ListItem))*">
    <xsl:param name="future-separators" as="map(xs:integer, element(ListItem))*"/>
    <xsl:param name="instruction" as="element(ListItem)?"/>
    <xsl:sequence select="for $s in $future-separators
                          return for $k in map:keys($s)
                                 return if (map:get($s, $k) is $instruction)
                                        then map{$k: map:get($s, $k)} 
                                        else ()"/>
<!--    <xsl:sequence select="map:for-each($future-separators, function($k, $v){ … })"/> didn’t work in Saxon 9.8-->
  </xsl:function>
  
  <xsl:function name="idml2xml:repetition-for-instruction" as="xs:integer?">
    <xsl:param name="instruction" as="element(ListItem)?"/>
    <xsl:param name="context" as="node()"/>
    <!-- Can Dropcap also have repetition or is the amount of characters only controlled by @DropCapCharacters? -->
    <xsl:sequence select="if ($instruction/Delimiter = 'Dropcap')
                          then 
                          for $style-cascade in (
                            for $s in key('idml2xml:by-Self', 'ParagraphStyle/' || $context/ancestor-or-self::*[@aid:pstyle][1]/@aid:pstyle, root($context)) 
                            return idml2xml:style-ancestors-and-self($s)
                          )
                          return 
                            for $d in (root($context)/idml2xml:doc/*:Preferences/TextDefault/@DropCapCharacters,
                                       $style-cascade/@DropCapCharacters)[last()][. > 0] 
                            return xs:integer($d)
                          else 
                          for $r in $instruction/Repetition[. castable as xs:integer]
                          return xs:integer($r)"/>
  </xsl:function>

  <xsl:template match="ListItem[@type = 'record']
                               [Delimiter]" mode="idml2xml:apply-nested-style-instruction"
                as="map(xs:integer, element(ListItem))?">
    <xsl:param name="string" as="xs:string" tunnel="yes">
      <!-- the total string (posibly including previous next nodes’ content) that isn’t consumed by an instruction yet -->
    </xsl:param>
    <xsl:param name="text-node" as="text()" tunnel="yes">
      <!-- the current text node -->
    </xsl:param>
    <xsl:variable name="instruction" as="element(ListItem)" select="."/>
    
    <xsl:variable name="regex" as="xs:string?" select="
      if ($instruction/Delimiter = 'Dropcap')
      then for $style-cascade in (for $s in key('idml2xml:by-Self', 'ParagraphStyle/' || $text-node/ancestor::*[@aid:pstyle][1]/@aid:pstyle) 
                                 return idml2xml:style-ancestors-and-self($s))
           return for $d in (root($text-node)/idml2xml:doc/*:Preferences/TextDefault/@DropCapCharacters,
                             $style-cascade/@DropCapCharacters)[last()][. > 0] 
                  return idml2xml:dropcap-regex(xs:integer($d))
      else if ($instruction/Delimiter = 'AnyWord') 
           then '[^' || idml2xml:NestedStyles-Delimiter-to-regex-chars(.) || ']+'
           else '[' || idml2xml:NestedStyles-Delimiter-to-regex-chars(.) || ']'"/>
    <xsl:variable name="applied" as="document-node()">
      <xsl:document>
        <xsl:if test="exists($regex) and not($regex = '[]')">
          <xsl:analyze-string select="$string" regex="{$regex}" flags="s">
            <xsl:matching-substring>
              <xsl:if test="$instruction/Inclusive = 'true'">
                <xsl:value-of select="."/>
              </xsl:if>
              <idml2xml:sep match="{.}">
                <xsl:sequence select="$instruction"/>
              </idml2xml:sep>
              <xsl:if test="$instruction/Inclusive = 'false'">
                <xsl:value-of select="."/>
              </xsl:if>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
              <xsl:sequence select="."/>
            </xsl:non-matching-substring>
          </xsl:analyze-string>
        </xsl:if>
      </xsl:document>
    </xsl:variable>
    <xsl:if test="contains($text-node/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
      <xsl:message select="'applied:', $applied, string-length($string)"/>
    </xsl:if>
    <xsl:variable name="sep-count" as="xs:integer" select="count($applied/idml2xml:sep)"/>
    <xsl:variable name="para" as="element(*)" select="$text-node/ancestor::*[@aid:pstyle][1]"/>
    <xsl:variable name="end-of-para" as="xs:boolean" 
      select="empty($para//text()[idml2xml:is-para-text(., $para)][. >> $text-node])"/>
    <xsl:variable name="selected-sep" as="element(idml2xml:sep)?" 
      select="$applied/idml2xml:sep[position() = (if ($instruction/Repetition castable as xs:integer)
                                                  then if ($end-of-para and $sep-count lt xs:integer($instruction/Repetition))
                                                       then $sep-count
                                                       else xs:integer($instruction/Repetition)
                                                  else 1) (: don’t use idml2xml:repetition-for-instruction since it gives
                                                  the dropcap char count for dropcaps, but here we need the repetition proper :)
                                   ]"/>
    <xsl:variable name="string-before" as="xs:string*" select="$applied/text()[$selected-sep >> .]"/>
    <xsl:variable name="string-after" as="xs:string*" select="$applied/text()[. >> $selected-sep]"/>
    <xsl:variable name="word-boundary-after-AnyWord" as="xs:boolean">
      <xsl:choose>
        <xsl:when test="not($instruction/Delimiter = 'AnyWord')">
          <xsl:sequence select="true()"/>
        </xsl:when>
        <xsl:when test="string-length(string-join($string-after)) gt 0">
          <xsl:sequence select="true()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="matches($text-node, '[' || idml2xml:NestedStyles-Delimiter-to-regex-chars(.) || ']$', 's')">
              <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="next-text-node" as="text()?" 
                select="(
                          (for $p in $text-node/ancestor::*[@aid:pstyle][1]
                           return $p//text()[idml2xml:is-para-text(., $p)]
                          )[. >> $text-node]
                        )[1]"/>
              <xsl:choose>
                <xsl:when test="matches($next-text-node, '^[' || idml2xml:NestedStyles-Delimiter-to-regex-chars(.) || ']', 's')">
                  <xsl:sequence select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="false()"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="string-pos" as="xs:integer?" 
      select="if (exists($string-before))
              then string-length(string-join($string-before)) 
              else if (exists($selected-sep))
                   then 0
                   else ()"/>
    <xsl:variable name="offset" as="xs:integer" select="string-length($string) - string-length($text-node)"/>
    <xsl:if test="contains($text-node/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
      <xsl:message select="'RRRRRR ', $string, exists($selected-sep), $sep-count, '***', idml2xml:repetition-for-instruction($instruction, $text-node), '%%', $string-pos, '++', $offset"/>
    </xsl:if>
    <xsl:if test="exists($string-pos) and ($string-pos ge $offset) and $word-boundary-after-AnyWord">
      <xsl:sequence select="map{$string-pos - $offset: $instruction}"/>  
    </xsl:if>
  </xsl:template>

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
        <xsl:sequence select="'&#x9;&#x20;&#x2001;&#x2002;&#x2003;&#x2004;&#x2005;&#x2006;&#x2007;&#x2008;&#x2009;'"/>
        <!-- &#9; wasn’t included because AnyWord also looked at idml2xml:tab[empty(@role)], but this is not true any more 
             with the accumulator implementation -->
      </xsl:when>
      <xsl:when test="$instruction/Delimiter/@type = 'string' and $instruction/Delimiter = '^y'">
        <!-- right tab -->
        <xsl:sequence select="'&#xEA68;'"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter/@type = 'string'">
        <xsl:sequence select="functx:escape-for-regex($instruction/Delimiter)"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = 'Tabs'">
        <!-- maybe consider also other kinds of tabs than those with literal tab content? --> 
        <xsl:sequence select="'&#9;'"/>
      </xsl:when>
      <xsl:when test="$instruction/Delimiter = ('Letters')">
        <xsl:sequence select="'\p{L}'"/>
      </xsl:when>
      <!--<xsl:when test="$instruction/Delimiter = ('EndNestedStyle')">
        <!-\- no idea whether that’s adequate or whether this requires more actions, such as suppressing
             subsequent separators. Test file: 101024_86048_PRG -\->
        <xsl:sequence select="'.'"/>
      </xsl:when>-->
      <xsl:when test="$instruction/Delimiter = ('Dropcap')"/>
      <!--<xsl:otherwise>
        <xsl:sequence select="error(xs:QName('idml2xml:NestedStyles01'), $instruction/Delimiter)"/>
      </xsl:otherwise>-->
    </xsl:choose>
  </xsl:function>

  <xsl:template match="text()" mode="idml2xml:NestedStyles-create-separators">
    <xsl:variable name="context" as="text()" select="."/>
    <xsl:variable name="aa" as="map(xs:string, item()*)?" select="accumulator-after('nested-style-instruction')[1]"/>
    <xsl:variable name="separators" as="map(xs:integer, element(ListItem))?" 
      select="if (exists($aa?future-separators)) then map:merge(map:get($aa, 'future-separators')) else ()"/>
    <xsl:variable name="string-positions" as="xs:integer*" select="sort($separators ! map:keys(.))"/>
    <xsl:if test="contains(ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
      <!--<xsl:for-each select="accumulator-before('nested-style-instruction')[1]">
        <xsl:message select="'BBBBB', serialize(., map {'method': 'adaptive'})"/>
      </xsl:for-each>-->
      <xsl:message select="'TTTTTTT', string(.)"></xsl:message>
      <xsl:for-each select="$aa">
        <xsl:message select="'AAAAAA', serialize($separators, map {'method': 'adaptive'}), count($separators), serialize(., map {'method': 'adaptive'})"/>
      </xsl:for-each>
      <xsl:message select="'SSSSSS', $string-positions"></xsl:message>
    </xsl:if>
    <xsl:if test="empty($separators)">
      <xsl:copy-of select="$context"/>
    </xsl:if>
    <xsl:for-each select="$string-positions">
      <xsl:variable name="sequence-position" as="xs:integer" select="position()"/>
      <xsl:if test="$sequence-position = 1 and . > 0">
        <xsl:value-of select="substring($context, 1, .)"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test=". = 0">
          <xsl:apply-templates select="$separators(.)" mode="idml2xml:NestedStyles-create-separators_instructions"/>
          <xsl:value-of select="substring($context, 1, ($string-positions[$sequence-position + 1], string-length($context))[1])"/>
        </xsl:when>
        <xsl:when test=". = string-length($context)">
          <xsl:apply-templates select="$separators(.)" mode="idml2xml:NestedStyles-create-separators_instructions"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="$separators(.)" mode="idml2xml:NestedStyles-create-separators_instructions"/>
          <xsl:value-of select="substring($context, . + 1, ($string-positions[$sequence-position + 1], string-length($context))[1] - .)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  
  <xsl:template match="ListItem" mode="idml2xml:NestedStyles-create-separators_instructions">
    <idml2xml:sep cstyle="{idml2xml:StyleName(AppliedCharacterStyle)}" 
      dtype="{if (Delimiter/@type = 'string') then 'string' else Delimiter}">
      <xsl:if test="Delimiter/@type = 'string'">
        <xsl:attribute name="string" select="Delimiter"/>
      </xsl:if>
      <xsl:if test="Delimiter = 'Dropcap'">
        <xsl:attribute name="lines" 
          select="for $style-cascade in idml2xml:style-ancestors-and-self(ancestor::ParagraphStyle)
                  return 
                    for $d in (/idml2xml:doc/*:Preferences/TextDefault/@DropCapLines,
                               $style-cascade/@DropCapLines)[last()][. > 0] 
                    return xs:integer($d)"/>
      </xsl:if>
      <xsl:attribute name="incl" select="Inclusive"/>
    </idml2xml:sep>
  </xsl:template>
  
  
  
  <xsl:template match="*[@aid:pstyle]
    [key('idml2xml:nested-style', concat('ParagraphStyle/', @aid:pstyle))]
    [key('idml2xml:by-Self', concat('ParagraphStyle/', @aid:pstyle))[not(@EmptyNestedStyles='true')]]"
    mode="idml2xml:NestedStyles-apply" priority="1">
    <xsl:next-match>
      <xsl:with-param name="seps" as="element(idml2xml:sep)*" tunnel="yes" 
        select="descendant::idml2xml:sep[idml2xml:same-scope(., current())]"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="  idml2xml:genPara[text()[idml2xml:is-para-text(., current())]]
                                         [.//idml2xml:sep]" 
                mode="idml2xml:NestedStyles-apply">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-adjacent="exists(self::idml2xml:genSpan)">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="apply-nested-styles">
              <xsl:with-param name="span-context" select="()"/>
              <xsl:with-param name="nodes" select="current-group()"/>
            </xsl:call-template>      
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan" mode="idml2xml:NestedStyles-apply">
    <xsl:param name="seps" as="element(idml2xml:sep)*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="exists($seps)">
        <xsl:call-template name="apply-nested-styles">
          <xsl:with-param name="span-context" select="."/>
        </xsl:call-template>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="apply-nested-styles">
    <xsl:param name="seps" as="element(idml2xml:sep)*" tunnel="yes"/>
    <xsl:param name="nodes" as="node()*" select="node()"/>
    <xsl:param name="span-context" as="element(idml2xml:genSpan)?"/>
    <xsl:for-each-group select="$nodes" group-ending-with="*[exists((self::idml2xml:sep | self::idml2xml:tab/idml2xml:sep) intersect $seps)]">
      <!-- intersect $seps is necessery when only Dropcap seps should be considered, as per the (now obsolete and removed)
           template that passes $dropseps as the seps param -->
      <xsl:variable name="following-sep" as="element(idml2xml:sep)?" select="($seps[. >> current-group()[last()]])[1]"/>
      <xsl:if test="contains(current-group()/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
        <xsl:message select="'&#xa;sssss', $seps"/>
        <xsl:message select="'nnnnn', current-group()"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="exists(
                          current-group()[last()]/(self::idml2xml:sep | self::idml2xml:tab[idml2xml:sep])
                          intersect $seps
                        )">
          <xsl:if test="contains(current-group()/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
            <xsl:message select="'var:A', current-group()"/>
          </xsl:if>
          <idml2xml:genSpan>
            <xsl:variable name="nested-cstyle" as="attribute(cstyle)" select="current-group()[last()]/(@cstyle | idml2xml:sep/@cstyle)"/>
            <xsl:attribute name="aid:cstyle" select="$nested-cstyle"/>
            <xsl:attribute name="idml2xml:rst" select="$nested-cstyle"/>
            <xsl:if test="exists(current-group()[last()]/(@lines | idml2xml:sep/@lines))">
              <xsl:attribute name="DropCapLines" select="current-group()[last()]/(@lines | idml2xml:sep/@lines)"/>
            </xsl:if>
            <xsl:choose>
              <xsl:when test="exists($span-context)">
                <xsl:call-template name="apply-nested-styles_process-original-span">
                  <xsl:with-param name="span-context" as="element(idml2xml:genSpan)" select="$span-context"/>
                  <xsl:with-param name="nested-cstyle" as="attribute(cstyle)" select="$nested-cstyle"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="#current"/>
              </xsl:otherwise>
            </xsl:choose>
          </idml2xml:genSpan>
        </xsl:when>
        <xsl:when test="exists($following-sep)">
          <!-- The first group doesn’t end with a sep or a tab with a sep, otherwise the first when branch would have
               kicked in. If there is a sep in the text that follows the current span, use its @cstyle value. -->
          <xsl:if test="contains(current-group()/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
            <xsl:message select="'var:B', current-group()"/>
          </xsl:if>
          <idml2xml:genSpan>
            <xsl:attribute name="aid:cstyle" select="$following-sep/@cstyle"/>
            <xsl:attribute name="idml2xml:rst" select="$following-sep/@cstyle"/>
            <xsl:if test="exists($following-sep/@lines)">
              <xsl:attribute name="DropCapLines" select="$following-sep/@lines"/>
            </xsl:if>
            <xsl:choose>
              <xsl:when test="exists($span-context)">
                <xsl:call-template name="apply-nested-styles_process-original-span">
                  <xsl:with-param name="span-context" as="element(idml2xml:genSpan)" select="$span-context"/>
                  <xsl:with-param name="nested-cstyle" as="attribute(cstyle)" select="$following-sep/@cstyle"/>
                </xsl:call-template>    
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="#current"/>
              </xsl:otherwise>
            </xsl:choose>
          </idml2xml:genSpan>
        </xsl:when>
        <xsl:when test="exists($span-context)">
          <!-- in a span without immediate seps (will this branch be reached at all?) -->
          <xsl:if test="contains(current-group()/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
            <xsl:message select="'var:C', current-group()"/>
          </xsl:if>
          <idml2xml:genSpan>
            <xsl:apply-templates select="$span-context/@*" mode="#current"/>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </idml2xml:genSpan>
        </xsl:when>
        <xsl:otherwise>
          <!-- in a para, in a group that doesn’t end with a sep -->
          <xsl:choose>
            <xsl:when test="exists($following-sep)">
              <xsl:if test="contains(current-group()/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
                <xsl:message select="'var:D1', $seps"/>
              </xsl:if>
              <idml2xml:genSpan>
                <xsl:attribute name="aid:cstyle" select="$following-sep/@cstyle"/>
                <xsl:attribute name="idml2xml:rst" select="$following-sep/@cstyle"/>
                <xsl:apply-templates select="current-group()" mode="#current"/>
              </idml2xml:genSpan>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="contains(current-group()/ancestor::*[@aid:pstyle][1]/@srcpath, $nested-styles-debugging-srcpath)">
                <xsl:message select="'var:D2', $seps"/>
              </xsl:if>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="apply-nested-styles_process-original-span">
    <xsl:param name="span-context" as="element(idml2xml:genSpan)"/>
    <xsl:param name="nested-cstyle" as="attribute(cstyle)"/>
    <xsl:choose>
      <xsl:when test="$span-context/@aid:cstyle = $nested-cstyle">
        <!-- don’t wrap 2 spans if they share the same cstyle, only process overrides 
             (plus the identical cstyle atts) and content -->  
        <xsl:apply-templates select="$span-context/@*" mode="#current"/>
        <xsl:apply-templates select="current-group()" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
      <idml2xml:genSpan>
        <xsl:apply-templates select="$span-context/@*" mode="#current"/>
        <xsl:apply-templates select="current-group()" mode="#current"/>
      </idml2xml:genSpan>    
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="idml2xml:sep" mode="idml2xml:NestedStyles-apply"/>
  
  <xsl:template match="idml2xml:tab[@role = 'footnotemarker'][. = 'Fn']/text()" mode="idml2xml:NestedStyles-apply"/>
  
  <xsl:template match="idml2xml:tab[@role = 'end-nested-style'][. = '&#xEA63;']/text()" mode="idml2xml:NestedStyles-apply"/>
  
  <xsl:template match="idml2xml:tab[@role = 'indent-to-here'][. = '&#xEA67;']/text()" mode="idml2xml:NestedStyles-apply"/>
  
  <xsl:template match="idml2xml:tab[@role = 'right'][. = '&#xEA68;']/text()" mode="idml2xml:NestedStyles-apply"/>

  <!-- Collateral in mode idml2xml:XML-Hubformat-modify-table-styles for grouping css:initial-letter
       so that there is a single inline element with this property at the beginning of a para -->

  <xsl:template match="*[dbk:phrase[@css:initial-letter]]" mode="idml2xml:XML-Hubformat-modify-table-styles">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-adjacent="(self::dbk:phrase[@css:initial-letter]
                                                             | (self::node()[not(normalize-space())] | self::comment() | self::processing-instruction())
                                                                     [preceding-sibling::node()[1]/self::dbk:phrase[@css:initial-letter]]
                                                                     [following-sibling::node()[1]/self::dbk:phrase[@css:initial-letter]]
                                                          )/(self::dbk:phrase/@css:initial-letter
                                                             | preceding-sibling::node()[1]/self::dbk:phrase/@css:initial-letter
                                                             | following-sibling::node()[1]/self::dbk:phrase/@css:initial-letter
                                                            )[1] => string()
                                                          ">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <phrase xmlns="http://docbook.org/ns/docbook" css:initial-letter="{current-grouping-key()}">
              <xsl:apply-templates select="current-group()" mode="#current">
                <xsl:with-param name="remove-initial-letter-css" tunnel="yes" select="true()" as="xs:boolean"/>
              </xsl:apply-templates>
            </phrase>    
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@css:initial-letter" mode="idml2xml:XML-Hubformat-modify-table-styles">
    <xsl:param name="remove-initial-letter-css" as="xs:boolean?" tunnel="yes"/>
    <xsl:if test="not($remove-initial-letter-css)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>