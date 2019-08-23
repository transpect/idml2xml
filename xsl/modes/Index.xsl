<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  exclude-result-prefixes = "idPkg aid5 aid xs"
>
  <!--== KEYs ==-->
  <xsl:key name="topic" match="Topic" use="@Self"/>
  <xsl:key name="hyperlink" match="Hyperlink" use="@Source"/>
  <xsl:key name="destination" match="HyperlinkURLDestination" use="@Self"/>
  <xsl:key name="by-Self" match="*[@Self]" use="@Self"/>

  <!--== mode: IndexTerms ==-->
  <xsl:template match="*" mode="idml2xml:IndexTerms-extract">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="idml2xml:index" mode="idml2xml:IndexTerms-extract">
    <xsl:param name="all-pagerefs" as="element(PageReference)*" tunnel="yes"/>
    <xsl:apply-templates 
      select=".//Topic[CrossReference] 
              | .//Topic[empty(CrossReference|Topic[normalize-space(@Name)])]
                         [not(@Self = $all-pagerefs/@ReferencedTopic)]" mode="#current" />
  </xsl:template>

  <xsl:template match="text()" mode="idml2xml:IndexTerms-extract" />

  <xsl:template match="PageReference" mode="idml2xml:IndexTerms-extract">
    <xsl:variable name="embedded-story" select="ancestor::Story[parent::TextFrame]/@Self" as="xs:string*" />
    <xsl:variable name="rt" as="xs:string" select="replace(@ReferencedTopic, 'Topicn$', '')"/>
    <xsl:variable name="topics" 
      select="if (
                    count(key('topic', $rt)) gt 1 
                    and 
                    key('topic', $rt)[@SortOrder[normalize-space(.)]]
                 )
              then key('topic', $rt)[@SortOrder[normalize-space(.)]] 
              else key('topic', $rt)" as="element(Topic)*"/>
    <xsl:apply-templates select="$topics" mode="#current">
      <xsl:with-param name="embedded-story" select="$embedded-story" tunnel="yes" />
      <xsl:with-param name="page-reference" select="@Self" tunnel="yes" />
      <xsl:with-param name="idml2xml:sourcepage" select="@idml2xml:sourcepage" tunnel="yes" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="Topic" mode="idml2xml:IndexTerms-extract">
    <xsl:apply-templates select="ancestor-or-self::Topic[last()]" mode="idml2xml:IndexTerms-Topics">
      <xsl:with-param name="terminal" select="." tunnel="yes" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="Topic" mode="idml2xml:IndexTerms-Topics">
    <xsl:param name="terminal" as="element(Topic)" tunnel="yes" />
    <xsl:param name="embedded-story" as="xs:string*" tunnel="yes" />
    <xsl:param name="page-reference" as="xs:string?" tunnel="yes" />
    <xsl:param name="idml2xml:sourcepage" as="xs:string?" tunnel="yes" />
    <xsl:if test="some $t in descendant-or-self::Topic satisfies ($t is $terminal)">
      <xsl:copy>
        <xsl:copy-of select="@*" />
        <xsl:if test="exists($embedded-story) and (. is $terminal)">
          <xsl:attribute name="in-embedded-story" select="$embedded-story" />
        </xsl:if>
        <xsl:if test="exists($page-reference) and (. is $terminal)">
          <xsl:attribute name="page-reference" select="$page-reference" />
        </xsl:if>
        <xsl:if test="$idml2xml:sourcepage ne '' and (. is $terminal)">
          <xsl:attribute name="idml2xml:pagenum-of-freely-placed-textframe" select="$idml2xml:sourcepage" />
        </xsl:if>
        <xsl:apply-templates mode="#current" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@SortOrder" mode="idml2xml:IndexTerms">
    <xsl:attribute name="sortas" select="."/>
  </xsl:template>

  <xsl:template match="@SortOrder[not(normalize-space())]" mode="idml2xml:IndexTerms"/>

  <!-- begin and end of print page -->

  <!-- BEGIN: new indesign script -->
  <xsl:template match="Hyperlink" mode="idml2xml:IndexTerms-extract">
    <xsl:apply-templates select="key('destination', Properties/Destination)" mode="#current" />
  </xsl:template>

  <xsl:template match="HiddenText[some $a in .//@*:AppliedConditions satisfies (matches($a, 'Condition/PageStart'))]" mode="idml2xml:IndexTerms-extract">
    <pagestart num="{replace(normalize-space(string-join(.//Content/text(),'')), '^.*_(\d+)$', '$1')}"/>
  </xsl:template>

  <xsl:template match="HiddenText[some $a in .//@*:AppliedConditions satisfies (matches($a, 'Condition/PageEnd'))]" mode="idml2xml:IndexTerms-extract">
    <pageend num="{replace(normalize-space(string-join(.//Content/text(),'')), '^.*_(\d+)$', '$1')}"/>
  </xsl:template>
  <!-- END: new indesign script -->

  <!-- BEGIN: old indesign script -->
  <xsl:template match="HyperlinkURLDestination[matches(@DestinationURL, '^page_')]" mode="idml2xml:IndexTerms-extract">
    <pagestart num="{replace(@DestinationURL, '^page_', '')}" />
  </xsl:template>

  <xsl:template match="HyperlinkURLDestination[matches(@DestinationURL, '^endpage_')]" mode="idml2xml:IndexTerms-extract">
    <pageend num="{replace(@DestinationURL, '^endpage_', '')}" />
  </xsl:template>
  <!-- END: old indesign script -->


  <xsl:template match="idml2xml:indexterms" mode="idml2xml:IndexTerms">
    <xsl:copy>
      <xsl:for-each-group select="*" group-ending-with="*[self::pageend]">
        <xsl:if test="exists(current-group()/self::Topic)">
          <xsl:apply-templates select="current-group()/self::Topic" mode="#current">
            <xsl:with-param name="pagenum" 
              select="(
                        @idml2xml:pagenum-of-freely-placed-textframe, 
                        current-group()/self::pageend/@num
                      )[1]" />
            <xsl:with-param name="pagenum-is-from-freely-placed-textframe" 
              select="if(@idml2xml:pagenum-of-freely-placed-textframe ne '') then true() else false()" />
          </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Topic[not(parent::Topic)]" mode="idml2xml:IndexTerms">
    <xsl:param name="pagenum" as="xs:string?" />
    <xsl:param name="silent" as="xs:boolean?" tunnel="yes"/>
    <xsl:param name="pagenum-is-from-freely-placed-textframe" as="xs:boolean" />
    <xsl:variable name="crossrefs" select="CrossReference" as="element(CrossReference)*"/>
    <xsl:variable name="see-or-seealso" as="element()*" select="idml2xml:index-crossrefs(.)"/>
    <xsl:if test="exists(Topic) or empty($see-or-seealso)">
      <indexterm>
        <xsl:attribute name="xml:id" 
          select="idml2xml:generate-indexterm-id($idml2xml:basename, (@page-reference, generate-id())[1])" />
        <xsl:copy-of select="@page-reference"/>
        <xsl:choose>
          <xsl:when test="exists($pagenum)">
            <xsl:attribute name="pagenum" select="$pagenum"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="not($silent)">
              <xsl:message>No page number for topic <xsl:sequence select="."/>
              </xsl:message>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$pagenum-is-from-freely-placed-textframe">
          <xsl:attribute name="pagenum-is-from-freely-placed-textframe" select="'yes'"/>
        </xsl:if>
        <xsl:if test="exists($crossrefs) and not(exists(idml2xml:index-crossrefs(.)))">
          <xsl:attribute name="{if ($crossrefs[1]/@CrossReferenceType eq 'See') then 'see' else 'seealso'}-crossref-topics" 
            select="distinct-values(for $cr in $crossrefs return replace($cr/@ReferencedTopic, 'Topicn$', ''))"/>
        </xsl:if>
        <primary>
          <xsl:apply-templates select="@SortOrder" mode="#current"/>
          <xsl:copy-of select="@in-embedded-story" />
          <xsl:value-of select="@Name"/>
        </primary>
        <xsl:apply-templates mode="#current" />
      </indexterm>
    </xsl:if>
    <xsl:if test="exists($see-or-seealso)">
      <indexterm>
        <xsl:attribute name="xml:id" 
          select="idml2xml:generate-indexterm-id($idml2xml:basename, (@page-reference, generate-id())[1])" />
        <xsl:copy-of select="@page-reference"/>
        <xsl:if test="exists($pagenum)">
          <xsl:attribute name="pagenum" select="$pagenum"/>
        </xsl:if>
        <xsl:if test="$pagenum-is-from-freely-placed-textframe">
          <xsl:attribute name="pagenum-is-from-freely-placed-textframe" select="'yes'"/>
        </xsl:if>
        <primary>
          <xsl:apply-templates select="@SortOrder" mode="#current"/>
          <xsl:copy-of select="@in-embedded-story"/>
          <xsl:value-of select="@Name"/>
        </primary>
        <xsl:sequence select="$see-or-seealso"/>
      </indexterm>
    </xsl:if>
  </xsl:template>

  <xsl:variable name="level-element-name" as="xs:string+"
    select="('primary', 'secondary', 'tertiary', 'quaternary', 'quinary', 'senary', 'septenary', 'octonary', 'nonary', 'denary')"/>

  <xsl:template match="Topic[not(parent::Topic)]//Topic[normalize-space(@Name)]" mode="idml2xml:IndexTerms">
    <xsl:param name="pagenum" as="xs:string?" />
    <xsl:param name="silent" as="xs:boolean?" tunnel="yes"/>
    <xsl:param name="pagenum-is-from-freely-placed-textframe" as="xs:boolean?" />
    <xsl:variable name="crossrefs" select="CrossReference" as="element(CrossReference)*"/>
    <xsl:variable name="see-or-seealso" as="element()*" select="idml2xml:index-crossrefs(.)"/>
    <xsl:element name="{$level-element-name[count(current()/ancestor::Topic) + 1]}">
      <xsl:if test="@page-reference">
        <xsl:attribute name="xml:id" select="idml2xml:generate-indexterm-id($idml2xml:basename, @page-reference)" />
        <xsl:copy-of select="@page-reference"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="exists($pagenum)">
          <xsl:attribute name="pagenum" select="$pagenum"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="not($silent)">
            <xsl:message>No page number for topic <xsl:sequence select="."/>
            </xsl:message>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="$pagenum-is-from-freely-placed-textframe">
        <xsl:attribute name="pagenum-is-from-freely-placed-textframe" select="'yes'"/>
      </xsl:if>
      <xsl:apply-templates select="@SortOrder" mode="#current"/>
      <xsl:copy-of select="@in-embedded-story"/>
      <xsl:value-of select="@Name"/>
    </xsl:element>
    <xsl:if test="exists(Topic) or empty($see-or-seealso)">
      <xsl:apply-templates mode="#current" />
    </xsl:if>
    <xsl:if test="exists($see-or-seealso)">
      <xsl:sequence select="$see-or-seealso"/>
    </xsl:if>
  </xsl:template>
  

  <xsl:function name="idml2xml:index-crossrefs" as="item()*"><!-- see or seealso -->
    <xsl:param name="topic" as="element(Topic)" />
    <xsl:for-each select="$topic/CrossReference[matches(@CrossReferenceType, 'Also')]/@ReferencedTopic">
      <xsl:variable name="referenced-topic" select="key('idml2xml:by-Self', replace(., 'Topicn$', ''))" as="element(Topic)*"/>
      <seealso>
        <xsl:if test="exists($referenced-topic/@page-reference)">
          <xsl:attribute name="linkend" 
            select="idml2xml:generate-indexterm-id($idml2xml:basename, ($referenced-topic/@page-reference)[1])"/>
        </xsl:if>
        <!--<xsl:comment select="$topic/@Self, '|', $topic/@Name, '|',., '|', $referenced-topic/@page-reference"></xsl:comment>-->
        <xsl:value-of select="replace(
                                substring-after(
                                  replace(., 'Topicn$', ''),
                                  'Topicn'
                                ), 
                                'Topicn', 
                                ', '
                              )" />
      </seealso>
    </xsl:for-each>
    <xsl:variable name="see-refs" as="xs:string*"
      select="for $rt in $topic/CrossReference[not(matches(@CrossReferenceType, 'Also'))]/@ReferencedTopic
              return replace($rt, 'Topicn$', '')"/>
    <xsl:if test="count(distinct-values($see-refs)) gt 0">
      <xsl:variable name="errors" as="element(error)*">
        <xsl:if test="count(distinct-values($see-refs)) gt 1">
          <xsl:message>There are many see-like crossrefs in index topic <xsl:value-of select="$topic/@Self"/> where only
            one is permitted. (<xsl:copy-of select="$topic/CrossReference[not(matches(@CrossReferenceType, 'Also'))]"/>)
          </xsl:message>
          <!--<error role="different-crossrefs" condition="{string-join($see-refs, '; ')}"/>-->
        </xsl:if>
        <xsl:if test="exists($topic/Topic) 
                      and 
                      (some $c in $topic/CrossReference satisfies (not(matches($c/@CrossReferenceType, 'Also'))))">
          <xsl:message>See-like crossref in index topic <xsl:value-of select="$topic/@Self"/> conflicts with sub-topics
          </xsl:message>
          <error role="subtopics-with-see"/>
        </xsl:if>
      </xsl:variable>
      <xsl:for-each-group select="(key('topic', distinct-values($see-refs), root($topic)))(:[1]:)"
        group-by="@Self">
        <see>
          <xsl:if test="exists(@page-reference)">
            <xsl:attribute name="linkend" 
              select="idml2xml:generate-indexterm-id($idml2xml:basename, @page-reference)"/>
          </xsl:if>
          <xsl:sequence select="$errors" />
          <xsl:value-of select="string-join(ancestor-or-self::Topic/@Name, ', ')" />
        </see>
      </xsl:for-each-group>
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="idml2xml:indexterm-signature" as="xs:string">
    <xsl:param name="indexterm" as="element(indexterm)"/><!-- no namespace -->
    <xsl:sequence select="string-join(for $n in $level-element-name return $indexterm/*[name() = $n], '____')"/>
  </xsl:function>
  
  <!--<xsl:template match="idml2xml:indexterms/indexterm" mode="idml2xml:SeparateParagraphs"></xsl:template>-->
  
  <!-- eliminate duplicates in the next pass (collateral) -->
  <xsl:template match="idml2xml:indexterms" mode="idml2xml:SeparateParagraphs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="indexterm" group-by="idml2xml:indexterm-signature(.)">
        <xsl:for-each-group select="current-group()" group-by="(.//@page-reference, '~')[1]">
          <xsl:sort select="current-grouping-key()" order="ascending"/>
          <xsl:copy>
            <xsl:copy-of select="@*, .//@xml:id, .//@page-reference, .//@in-embedded-story"/>
            <xsl:if test="current-grouping-key() = '~'">
              <xsl:attribute name="role" select="'hub:not-placed-on-page'"/>
            </xsl:if>
            <xsl:if test="exists(current-group()/seealso)">
              <xsl:attribute name="has-seealso"/>
            </xsl:if>
            <xsl:if test="exists(current-group()/see)">
              <xsl:attribute name="has-see"/>
            </xsl:if>
            <xsl:apply-templates select="*[name() = $level-element-name]" mode="#current"/>
            <xsl:if test="position() = 1">
              <xsl:for-each-group select="current-group()/seealso" group-by=".">
                <xsl:copy>
                  <xsl:copy-of select="current-group()/@*"/>
                  <xsl:copy-of select="node()"/>
                </xsl:copy>
              </xsl:for-each-group>
              <xsl:for-each-group select="current-group()/see" group-by=".">
                <xsl:copy>
                  <xsl:copy-of select="current-group()/@*"/>
                  <xsl:copy-of select="node()"/>
                </xsl:copy>
              </xsl:for-each-group>
            </xsl:if>
          </xsl:copy>
        </xsl:for-each-group>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[name() = $level-element-name]/@*[name() = ('in-embedded-story', 'page-reference', 'xml:id')]"
    mode="idml2xml:SeparateParagraphs"/>
  
  <xsl:template match="indexterm[count(see) gt 1]" mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br">
    <xsl:variable name="context" as="element(indexterm)" select="."/>
    <xsl:for-each select="see">
      <xsl:variable name="id" as="xs:string" 
        select="string-join(
                  (
                    (@xml:id, 
                     concat('ie_', $idml2xml:basename, '_', generate-id(..))
                    )[1], 
                    if (position() gt 1) then string(position()) else ()
                  ), '__see')"/>
      <xsl:variable name="current-see" as="element(see)" select="."/>
      <xsl:for-each select="$context">
        <xsl:copy>
          <xsl:attribute name="xml:id" select="$id"/>
          <xsl:apply-templates select="@* except @xml:id, node() except see, see[. is $current-see]" mode="#current"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- eliminate those indexterms whose seealso references have been moved to another indexterm that resides on a page -->
  <xsl:template match="idml2xml:indexterms/indexterm[empty(seealso)]
                                                    [@has-seealso]
                                                    [empty(@page-reference)]" 
    mode="idml2xml:ConsolidateParagraphStyleRanges"/>
  
  


  <!-- This is used for handling of indexterms in the regular idml2hub pipeline 
    (collateral to idml2xml:SeparateParagraphs-pull-down-psrange) -->
  <xsl:template match="idml2xml:index" mode="idml2xml:SeparateParagraphs-pull-down-psrange" >
    <xsl:variable name="idml2xml:IndexTerms-extract" as="document-node(element(idml2xml:indexterms))">
      <xsl:document>
        <idml2xml:indexterms>
          <xsl:apply-templates select="/" mode="idml2xml:IndexTerms-extract">
            <xsl:with-param name="all-pagerefs" as="element(PageReference)*" select="//PageReference" tunnel="yes"/>
          </xsl:apply-templates>
        </idml2xml:indexterms>
      </xsl:document>
    </xsl:variable>
    <!--<debug>
      <xsl:sequence select="$idml2xml:IndexTerms-extract"></xsl:sequence>
    </debug>-->
    <xsl:apply-templates select="$idml2xml:IndexTerms-extract/idml2xml:indexterms" mode="idml2xml:IndexTerms">
      <xsl:with-param name="silent" select="true()" as="xs:boolean" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:function name="idml2xml:generate-indexterm-id" as="xs:string">
    <xsl:param name="file-basename" as="xs:string"/>
    <xsl:param name="page-reference" as="xs:string"/>
    <xsl:sequence select="concat('ie_', $file-basename, '_', $page-reference)"/>
  </xsl:function>

  <xsl:template match="idml2xml:indexterms" mode="idml2xml:XML-Hubformat-add-properties" />

  <xsl:template match="idml2xml:index" mode="idml2xml:GenerateTagging" />

  <xsl:key name="indexterm-by-page-reference" match="idml2xml:indexterms/indexterm" use="@page-reference"/>

  <xsl:template match="PageReference" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:apply-templates select="key('indexterm-by-page-reference', @Self)" mode="#current">
      <xsl:with-param name="PageReference" select="." tunnel="no"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="indexterm/@page-reference | @in-embedded-story" 
    mode="idml2xml:XML-Hubformat-add-properties" priority="2"/>
  <xsl:template match="@has-seealso | @has-see" 
    mode="idml2xml:XML-Hubformat-remap-para-and-span" priority="2"/>

  <xsl:template match="indexterm | *[name() = $level-element-name] | see | seealso" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:param name="PageReference" select="()" as="element(PageReference)?" tunnel="no"/>
    <xsl:element name="{name()}" xmlns="http://docbook.org/ns/docbook">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$PageReference[starts-with(@PageNumberStyleOverride, 'CharacterStyle')]">
        <xsl:variable name="cstyle" as="element()?"
          select="key('by-Self', $PageReference/@PageNumberStyleOverride)"/>
        <xsl:if test="matches($cstyle/@FontStyle, 'Italic')">
          <xsl:attribute name="role" select="'hub:pagenum-italic'"/>
        </xsl:if>
        <xsl:if test="matches($cstyle/@FontStyle, 'Bold')">
          <xsl:attribute name="role" select="'hub:pagenum-bold'"/>
        </xsl:if>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="indexterm//@*" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:copy/>
  </xsl:template>



</xsl:stylesheet>
