<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:idml2xml  = "http://transpect.io/idml2xml"
  exclude-result-prefixes="idPkg aid5 aid xs saxon"
>

  <xsl:template match="idml2xml:genSpan[not(@*)]" mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[not(node())]"
		mode="idml2xml:AutoCorrect" priority="1.5" />

  <xsl:template match="idml2xml:genSpan[*[name() = ($idml2xml:shape-element-names, 'idml2xml:genFrame')]]
                                       [every $n in node() satisfies (name($n) = ($idml2xml:shape-element-names, 'idml2xml:genFrame'))]
                                       [not(@AppliedConditions[normalize-space()])]"
    mode="idml2xml:AutoCorrect" priority="1.5">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="idml2xml:genSpan
                         [string-length(.) eq 0]
                         [
                           not(*[name()=$idml2xml:idml-content-element-names])
                           and 
                           not(.//EPS or .//PDF or .//Image or .//WMF)
                         ]" mode="idml2xml:AutoCorrect" priority="1.25" >
  </xsl:template>


  <xsl:template match="idml2xml:genSpan[@aid:pstyle][not(../@aid:cstyle)]" mode="idml2xml:AutoCorrect">
    <idml2xml:genPara>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </idml2xml:genPara>
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedParagraphStyle ne @aid:pstyle]/@aid:pstyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="aid:pstyle" select="../@idml2xml:AppliedParagraphStyle" />
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedParagraphStyle ne @aid:pstyle]/@idml2xml:AppliedParagraphStyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="idml2xml:pstyle-was" select="../@aid:pstyle" />
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedCellStyle ne @aid5:cellstyle]/@idml2xml:AppliedCellStyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="idml2xml:cellstyle-was" select="../@aid5:cellstyle" />
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedCellStyle ne @aid5:cellstyle]/@aid5:cellstyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="aid5:cellstyle" select="../@idml2xml:AppliedCellStyle" />
  </xsl:template>
  
  <xsl:template match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, 'et1')]" mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template
    match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, '(et|cp)1')][idml2xml:genPara][every $c in * satisfies ($c/self::idml2xml:genPara)]" 
    mode="idml2xml:AutoCorrect" priority="3">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <!-- GI 2012-10-02
       I suppose this template is for dealing with tagging extraction. We had a case when an idml2xml:genTable was 
       unwrapped from the parastylerange and got an attached aid:pstyle attribute. This prolly doesn’t hurt, but
       we better leave the genTable in the genPara. -->
  <xsl:template
    match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, 'cp1')][count(*) eq 1][not(*/@aid:cstyle)][not(idml2xml:genTable)][not(idml2xml:genAnchor)]" 
    mode="idml2xml:AutoCorrect" priority="2">
    <xsl:element name="{name(*)}">
      <xsl:apply-templates select="*/@*" mode="#current"/>
      <xsl:attribute name="aid:pstyle" select="@AppliedParagraphStyle" />
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac2'), ' ')" />
      <xsl:apply-templates select="*/node()" mode="#current" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, 'cp1')]" mode="idml2xml:AutoCorrect">
    <idml2xml:genPara idml2xml:reason="cp1 ac1" aid:pstyle="{@AppliedParagraphStyle}" srcpath="{@srcpath}">
      <xsl:apply-templates mode="#current" />
    </idml2xml:genPara>
  </xsl:template>

  <!-- default handler, with the slight modification that it collects its ancestor ParagraphStyleRange’s @srcpath attribute -->
  <xsl:template match="idml2xml:genPara" mode="idml2xml:AutoCorrect">
    <xsl:copy>
      <xsl:apply-templates mode="#current"
        select="parent::idml2xml:ParagraphStyleRange/@*[not(name() = ('AppliedParagraphStyle', 'idml2xml:reason'))], @*"/>
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac13'), ' ')" />
      <xsl:apply-templates mode="#current"
        select="parent::idml2xml:ParagraphStyleRange/Properties"/>
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
  </xsl:template>
  
  <xsl:template 
    match="idml2xml:genPara[count(distinct-values(for $p in *[@aid:pstyle] return name($p))) eq 1]" 
    mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>


  <xsl:template match="idml2xml:genPara[idml2xml:contains(@idml2xml:reason, 'gp2')]" mode="idml2xml:AutoCorrect idml2xml:AutoCorrect-group-pseudoparas" priority="4">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac12'), ' ')" />
      <xsl:call-template name="group-pseudoparas">
        <xsl:with-param name="pstyle" select="@aid:pstyle" tunnel="yes"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[*/@aid:pstyle]" mode="idml2xml:AutoCorrect-group-pseudoparas">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac11'), ' ')" />
      <xsl:call-template name="group-pseudoparas" />
    </xsl:copy>
  </xsl:template>

  <xsl:template name="group-pseudoparas">
    <xsl:param name="pstyle" as="xs:string" tunnel="yes"/>
    <xsl:for-each-group select="node()[not(self::comment())]" group-adjacent="if (@aid:pstyle) then name() else false()">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:element name="{name()}">
            <xsl:copy-of select="current-group()[last()]/@*" />
            <xsl:if test="$srcpaths = 'yes'"><xsl:attribute name="srcpath" select="current-group()/@srcpath" /></xsl:if>
            <xsl:attribute name="idml2xml:reason" select="'ac6'" />
            <xsl:apply-templates select="current-group()/node()" mode="idml2xml:AutoCorrect" />
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="idml2xml:AutoCorrect-group-pseudoparas" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>


  <xsl:template match="@idml2xml:AppliedParagraphStyle[matches(../@idml2xml:reason, 'gp3')]" mode="idml2xml:AutoCorrect">
    <xsl:if test="../@aid:pstyle">
      <xsl:attribute name="idml2xml:pstyle-was" select="../@aid:pstyle" />
    </xsl:if>
    <xsl:attribute name="aid:pstyle" select="." />
  </xsl:template>



  <xsl:template match="*[@aid:cstyle]
                        [idml2xml:genSpan]
                        [count(*) eq 1]" mode="idml2xml:AutoCorrect">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="*/@*" /><!-- genSpan's cstyle will win -->
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, */@idml2xml:reason, 'ac10'), ' ')" />
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@aid:cstyle]
                        [idml2xml:genSpan]
                        [count(*) eq 1]/
                       idml2xml:genSpan" mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>



  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: idml2xml:AutoCorrect-clean-up -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="@idml2xml:AppliedParagraphStyle[. = ../@aid:pstyle]" mode="idml2xml:AutoCorrect-clean-up" />

  <xsl:template match="*[not(self::idml2xml:genPara)][@aid:pstyle]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:param name="genPara" as="element(idml2xml:genPara)?" tunnel="yes" />
    <xsl:choose>
      <xsl:when test="$genPara/@aid:pstyle and idml2xml:same-scope(., $genPara)">
        <xsl:copy>
          <xsl:copy-of select="@*" />
          <xsl:attribute name="aid:pstyle" select="$genPara/@aid:pstyle" />
          <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac8'), ' ')" />
          <xsl:apply-templates mode="#current" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- one kind of pstyled element, together with optional anchored objects and character ranges. Everything will be wrapped in an element like the last pstyled   -->
  <xsl:template match="idml2xml:genPara
                         [*[@aid:pstyle]]
                         [count(distinct-values(for $p in *[@aid:pstyle] return name($p))) eq 1]
                         [count(      *[@aid:pstyle] 
                                | *[@aid:cstyle] 
                                | *[@idml2xml:AppliedCharacterStyle] 
                                | *[@idml2xml:story]
                                | *[@idml2xml:layer]
                                | text()
                               ) 
                          eq count(node())
                         ]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:element name="{name(*[@aid:pstyle][last()])}">
      <xsl:copy-of select="*[@aid:pstyle][last()]/@*" />
      <!-- inner pstyle wins. is there any case where the outer pstyle is more important? -->
      <!--<xsl:attribute name="aid:pstyle" select="@aid:pstyle" />-->
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac7'), ' ')" />
      <xsl:apply-templates select="      *[@aid:pstyle]/node()
                                   union *[@aid:cstyle] 
                                   union *[@idml2xml:AppliedCharacterStyle] 
                                   union *[@idml2xml:story]
                                   union *[@idml2xml:layer]
                                   union text()" mode="#current" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[matches(@aid:cstyle, 'No.character.style')]
		                                   [parent::idml2xml:genPara[count(descendant::idml2xml:genSpan) = 1]]
		                                   [not(@*[not(matches(name(), '^(srcpath|idml2xml|aid)'))])]" 
		mode="idml2xml:AutoCorrect-clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- dissolve genSpans that contain only tables or rectangles because the information cannot be used later-->
  <xsl:template match="idml2xml:genSpan[idml2xml:genTable or Rectangle]
                                       [count(*) = (1, 2)]
                                       [every $text in text() satisfies (not(matches($text, '\S')))]
                                       [every $node in node()[not(self::text())] satisfies ($node/local-name() = ('Rectangle', 'genTable', 'Properties'))]
                                       [not(@AppliedConditions[normalize-space()]) and Rectangle]" 
                mode="idml2xml:AutoCorrect-clean-up" priority="3">
    <xsl:apply-templates select="*[self::idml2xml:genTable or self::Rectangle]" mode="#current"/>
  </xsl:template>

  <xsl:template match="HiddenText[empty(node())]" mode="idml2xml:AutoCorrect-clean-up" />
  
  
  <xsl:template match="idml2xml:genFrame[@idml2xml:elementName eq 'Group']
                                        [not(@idml2xml:layer eq 'PrintOnly')]
                                        [count(node()) eq 1]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
  <!-- make @srcpath unique: -->
  
  <xsl:key name="by-srcpath" match="*[@srcpath]" use="@srcpath"/>
  
  <xsl:template match="@srcpath" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:variable name="same-path-items" select="key('by-srcpath', .)/generate-id()" as="xs:string+"/>
    <xsl:choose>
      <xsl:when test="$srcpaths = 'no'"/>
      <xsl:when test="count($same-path-items) gt 1">
        <xsl:attribute name="srcpath" select="concat(., ';n=', index-of($same-path-items, generate-id(..)))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="srcpath" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Solve a situation like this:
   <idml2xml:parsep/>
   <idml2xml:genPara>
      <idml2xml:genAnchor/>
   </idml2xml:genPara>
   <idml2xml:link>
      <idml2xml:ParagraphStyleRange>
         <idml2xml:genPara>
         …
   The first idml2xml:genPara is not a para in its own right. Its content belongs to the beginning 
   of the subsequent idml2xml:genPara, if there is such.
  -->

  <xsl:template match="*[idml2xml:parsep]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="idml2xml:process-para-containers-in-AutoCorrect-clean-up"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="idml2xml:process-para-containers-in-AutoCorrect-clean-up">
    <xsl:for-each-group select="*" group-starting-with="idml2xml:parsep">
      <!-- an EndnoteRange that comprises multiple paras is in Hogrefe’s 101024_86048b_PRG,
      see https://redmine.le-tex.de/issues/8143 -->
      <xsl:choose>
        <xsl:when test="self::idml2xml:parsep">
          <xsl:choose>
            <xsl:when test="(count(current-group()[self::idml2xml:genPara]) gt 1)
                            and 
                            (every $elt in current-group() satisfies $elt[not(idml2xml:is-dissolvable-anchor-genPara(.))])">
              <!--  hogrefe.de/PPP/02773/idml/101026_02773_PPP.idml, paras splitted by crossreference source-->
              <xsl:for-each-group select="current-group()" group-adjacent="boolean(self::idml2xml:genPara)">
                <xsl:choose>
                  <xsl:when test="current-group()[self::idml2xml:genPara] 
                                                  and count(distinct-values(current-group()/@aid:pstyle)) = 1
                                                  and (contains(current-group()[2]/@srcpath, replace(current-group()[1]/@srcpath, '^.+?(Stories/Story_u35c9d.xml\?).+$', '$1')))">
                   <xsl:element name="genPara" namespace="http://transpect.io/idml2xml">
                     <xsl:apply-templates select="current-group()[1]/@*, current-group()/node()" mode="#current"/>
                   </xsl:element>
                </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="current-group()" mode="#current"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="(count(current-group()[self::idml2xml:genPara]) gt 1
                             ) and
                             current-group()[idml2xml:is-dissolvable-anchor-genPara(.)]">
                <xsl:message select="'AutoCorrect-clean-up: More than one para: ' , current-group()[last()]"/>
                <xsl:comment>❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧ unhandled!!!, <xsl:value-of select="count(current-group()[not(self::idml2xml:parsep)]
                  [not(idml2xml:is-dissolvable-anchor-genPara(.))]
                  )"/>
                </xsl:comment>
                <xsl:comment>
                  <xsl:for-each select="current-group()">
                    <xsl:sequence select="name(.)"/>
                  </xsl:for-each>
                </xsl:comment>
                <!-- this case wasn't thought of and has to be handled! -->
              </xsl:if>
              <xsl:apply-templates select="current-group()[not(idml2xml:is-dissolvable-anchor-genPara(.))]"
                mode="#current">
                <xsl:with-param name="insert-anchor" select="current-group()[idml2xml:is-dissolvable-anchor-genPara(.)]/*" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>


  <xsl:template match="*[@aid:pstyle]" mode="idml2xml:AutoCorrect-clean-up" priority="5">
    <xsl:param name="insert-anchor" as="element(idml2xml:genAnchor)*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="exists($insert-anchor)">
        <xsl:copy>
          <xsl:apply-templates select="@*,
                                       $insert-anchor,
                                       node()" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="idml2xml:genPara[idml2xml:is-dissolvable-anchor-genPara(.)]"
    mode="idml2xml:AutoCorrect-clean-up"/>
  
  <xsl:function name="idml2xml:is-dissolvable-anchor-genPara" as="xs:boolean">
    <xsl:param name="para" as="element(*)?"/>
    <xsl:sequence select="exists($para/preceding-sibling::*[1]/self::idml2xml:parsep)
                          and
                          exists($para/idml2xml:genAnchor)
                          and
                          (every $child in $para/* satisfies ($child/self::idml2xml:genAnchor))"/>
  </xsl:function>

  <xsl:template match="EndnoteRange" mode="idml2xml:AutoCorrect-clean-up" priority="1">
    <xsl:variable name="anchor" as="element(idml2xml:genAnchor)">
      <idml2xml:genAnchor xml:id="en-{@Self}" role="hub:endnote"/>  
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="exists(idml2xml:parsep)">
        <xsl:call-template name="idml2xml:process-para-containers-in-AutoCorrect-clean-up">
          <xsl:with-param name="first-endnote-para-anchor" tunnel="yes" select="$anchor"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$anchor"/>
        <xsl:apply-templates mode="#current"/>    
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="idml2xml:genPara[following-sibling::*[1]/self::EndnoteRange]
                                       [empty(node())]" mode="idml2xml:AutoCorrect-clean-up"/>
  
  <xsl:template match="idml2xml:genPara[preceding-sibling::*[1]/self::EndnoteRange]
                                       [empty(node())]" mode="idml2xml:AutoCorrect-clean-up"/>
  
  <xsl:template match="EndnoteRange/idml2xml:genPara[1]/node()[1]" mode="idml2xml:AutoCorrect-clean-up" priority="1">
    <xsl:param name="first-endnote-para-anchor" as="element(idml2xml:genAnchor)?" tunnel="yes"/>
    <xsl:sequence select="$first-endnote-para-anchor"/>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="EndnoteRange//idml2xml:tab[@role = 'footnotemarker']" mode="idml2xml:AutoCorrect-clean-up">
    <idml2xml:genSpan aid:cstyle="hub:identifier">
      <idml2xml:link remap="EndnoteMarker" linkend="endnoteAnchor-{ancestor::EndnoteRange[1]/@SourceEndnote}">
        <xsl:value-of select="key('by-Self', ancestor::EndnoteRange[1]/@SourceEndnote)/@idml2xml:per-story-endnote-num"/>
      </idml2xml:link>
    </idml2xml:genSpan>
  </xsl:template>

  <xsl:template match="Endnote" mode="idml2xml:AutoCorrect-clean-up">
    <idml2xml:link remap="EndnoteRange" linkend="en-{@EndnoteTextRange}">
      <xsl:attribute name="xml:id" select="string-join(('endnoteAnchor', @Self), '-')"/>
      <xsl:value-of select="@idml2xml:per-story-endnote-num"/>
    </idml2xml:link>
  </xsl:template>

</xsl:stylesheet>