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
  <xsl:key name="topic" match="Topic" use="@Self"/>
  <xsl:key name="hyperlink" match="Hyperlink" use="@Source"/>
  <xsl:key name="destination" match="HyperlinkURLDestination" use="@Self"/>

  <!--== mode: IndexTerms ==-->
  <xsl:template match="*" mode="idml2xml:IndexTerms-extract">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="text()" mode="idml2xml:IndexTerms-extract" />

  <xsl:template match="PageReference" mode="idml2xml:IndexTerms-extract">
    <xsl:variable name="embedded-story" select="ancestor::Story[parent::TextFrame]/@Self" as="xs:string*" />
    <xsl:apply-templates select="key('topic', @ReferencedTopic, $designmap-root)" mode="#current">
      <xsl:with-param name="embedded-story" select="$embedded-story" tunnel="yes" />
      <xsl:with-param name="page-reference" select="@Self" tunnel="yes" />
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
    <xsl:choose>
      <xsl:when test="some $t in descendant-or-self::Topic satisfies ($t is $terminal)">
        <xsl:copy>
          <xsl:copy-of select="@*" />
          <xsl:if test="exists($embedded-story)">
            <xsl:attribute name="in-embedded-story" select="$embedded-story" />
          </xsl:if>
          <xsl:if test="exists($page-reference)">
            <xsl:attribute name="page-reference" select="$page-reference" />
          </xsl:if>
          <xsl:apply-templates mode="#current" />
        </xsl:copy>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="HyperlinkTextSource" mode="idml2xml:IndexTerms-extract">
    <xsl:apply-templates select="key('hyperlink', @Self, $designmap-root)" mode="#current" />
  </xsl:template>

  <xsl:template match="Hyperlink" mode="idml2xml:IndexTerms-extract">
    <xsl:apply-templates select="key('destination', Properties/Destination, $designmap-root)" mode="#current" />
  </xsl:template>

  <xsl:template match="HyperlinkURLDestination[matches(@DestinationURL, '^page_')]" mode="idml2xml:IndexTerms-extract">
    <pagestart num="{replace(@DestinationURL, '^page_', '')}" />
  </xsl:template>

  <xsl:template match="HyperlinkURLDestination[matches(@DestinationURL, '^endpage_')]" mode="idml2xml:IndexTerms-extract">
    <pageend num="{replace(@DestinationURL, '^endpage_', '')}" />
  </xsl:template>


  <xsl:template match="idml2xml:indexterms" mode="idml2xml:IndexTerms">
    <xsl:copy>
      <xsl:for-each-group select="*" group-ending-with="*[self::pageend]">
        <xsl:if test="exists(current-group()/self::Topic)">
          <xsl:apply-templates select="current-group()/self::Topic" mode="#current">
            <xsl:with-param name="pagenum" select="(current-group()/self::pageend/@num)" />
          </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Topic[not(parent::Topic)]" mode="idml2xml:IndexTerms">
    <xsl:param name="pagenum" as="xs:string?" />
    <indexterm>
      <xsl:variable name="crossrefs" select="CrossReference" />
      <xsl:choose>
        <xsl:when test="exists($pagenum)">
          <xsl:attribute name="pagenum" select="$pagenum" />
        </xsl:when>
        <xsl:when test="exists($crossrefs)" />
        <xsl:otherwise>
          <xsl:message>No page number for topic <xsl:sequence select="." />
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
      <primary>
        <xsl:copy-of select="@in-embedded-story" />
        <xsl:value-of select="@Name"/>
        <xsl:sequence select="idml2xml:index-crossrefs(.)" />
      </primary>
      <xsl:apply-templates mode="#current" />
    </indexterm>
  </xsl:template>

  <xsl:template match="Topic[not(parent::Topic)]/Topic" mode="idml2xml:IndexTerms">
    <secondary>
      <xsl:copy-of select="@in-embedded-story" />
      <xsl:value-of select="@Name"/>
      <xsl:sequence select="idml2xml:index-crossrefs(.)" />
    </secondary>
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="Topic[not(parent::Topic)]/Topic/Topic" mode="idml2xml:IndexTerms">
    <tertiary>
      <xsl:copy-of select="@in-embedded-story" />
      <xsl:value-of select="@Name"/>
      <xsl:sequence select="idml2xml:index-crossrefs(.)" />
    </tertiary>
  </xsl:template>

  <!-- see-like entries in the designmap will be extracted in idml2xml.xsl, variable idml2xml:IndexTerms-extract -->

  <xsl:function name="idml2xml:index-crossrefs" as="element(*)*"><!-- see or seealso -->
    <xsl:param name="topic" as="element(Topic)" />
    <xsl:apply-templates select="key('topic', $topic/CrossReference[matches(@CrossReferenceType, 'Also')]/@ReferencedTopic, $designmap-root)" mode="idml2xml:IndexTerms-SeeAlso"/>
    <xsl:variable name="see-refs" select="$topic/CrossReference[not(matches(@CrossReferenceType, 'Also'))]/@ReferencedTopic" as="xs:string*"/>
    <xsl:if test="count(distinct-values($see-refs)) gt 0">
      <xsl:variable name="errors" as="element(error)*">
        <xsl:if test="count(distinct-values($see-refs)) gt 1">
          <xsl:message>There are many see-like crossrefs in index topic <xsl:value-of select="$topic/@Self"/> where only one is permitted.
          </xsl:message>
          <error role="different-crossrefs" condition="{string-join($see-refs, '; ')}"/>
        </xsl:if>
        <xsl:if test="exists($topic/Topic) 
                      and 
                      (some $c in $topic/CrossReference satisfies (not(matches($c/@CrossReferenceType, 'Also'))))">
          <xsl:message>See-like crossref in index topic <xsl:value-of select="$topic/@Self"/> conflicts with sub-topics
          </xsl:message>
          <error role="subtopics-with-see"/>
        </xsl:if>
      </xsl:variable>
      <xsl:for-each select="key('topic', $see-refs, $designmap-root)/@Name">
        <see>
          <xsl:sequence select="$errors" />
          <xsl:value-of select="." />
        </see>
      </xsl:for-each>
    </xsl:if>
  </xsl:function>

  <xsl:template match="Topic" mode="idml2xml:IndexTerms-SeeAlso">
    <seealso>
      <xsl:value-of select="@Name"/>
    </seealso>
  </xsl:template>

</xsl:stylesheet>