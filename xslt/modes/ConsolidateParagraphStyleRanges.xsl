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

  <!-- Please look at A5A, infobox "Folgende Lektüre" and TB before, for understanding the complexity.
       The div class="main" that spans both is difficult -->

  <xsl:template match="*[idml2xml:br-first(.)]" mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br">
    <idml2xml:Br class="first"/>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="idml2xml:ConsolidateParagraphStyleRanges-elim-br">
        <xsl:with-param name="elim" select="(.//Br[idml2xml:same-scope(., current())])[1]" tunnel="yes" />
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[idml2xml:br-last(.)]" mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="idml2xml:ConsolidateParagraphStyleRanges-elim-br">
        <xsl:with-param name="elim" select="(.//Br[idml2xml:same-scope(., current())])[last()]" tunnel="yes" />
      </xsl:apply-templates>
    </xsl:copy>
    <idml2xml:Br class="last"/>
  </xsl:template>

  <xsl:template match="*[idml2xml:br-first(.) and idml2xml:br-last(.)]" mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br" priority="2">
    <idml2xml:Br class="first-2"/>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="idml2xml:ConsolidateParagraphStyleRanges-elim-br">
        <xsl:with-param name="elim" select="(.//Br[idml2xml:same-scope(., current())])[position() = (1, last())]" tunnel="yes" />
      </xsl:apply-templates>
    </xsl:copy>
    <idml2xml:Br class="last-2"/>
  </xsl:template>

  <xsl:template match="Br" mode="idml2xml:ConsolidateParagraphStyleRanges-elim-br">
    <xsl:param name="elim" as="element(Br)+" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="some $br in $elim satisfies (. is $br)" />
      <xsl:otherwise>
        <xsl:next-match />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="idml2xml:ConsolidateParagraphStyleRanges-elim-br">
    <xsl:param name="elim" as="element(Br)+" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="descendant::Br[some $br in $elim satisfies (. is $br)]">
        <xsl:copy>
          <xsl:copy-of select="@*" />
          <xsl:apply-templates mode="idml2xml:ConsolidateParagraphStyleRanges-elim-br">
            <xsl:with-param name="elim" select="$elim" tunnel="yes" />
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- remove empty CharacterStyleRanges etc.
       It seems as if there are no templates that serve the original purpose.
       Ok, we'll use this mode under its historical name for splitting
       span elements that span line breaks, and for re-grouping CrossReferenceSources. -->

  <xsl:template match="*[CrossReferenceSource]" 
    mode="idml2xml:ConsolidateParagraphStyleRanges-remove-empty">
    <xsl:variable name="context" select="." as="element(XMLElement)" />
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:for-each-group select="*" group-adjacent="idml2xml:elt-signature(self::CrossReferenceSource)">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:copy>
              <xsl:copy-of select="@*" />
              <xsl:apply-templates select="current-group()" mode="#current" />
            </xsl:copy>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="CrossReferenceSource" mode="idml2xml:ConsolidateParagraphStyleRanges-remove-empty">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>


  <!-- collateral: divide span elements that span line breaks (CAVEAT: CHANGES ORIGINAL MARKUP!) -->
  <xsl:template match="XMLElement[XMLAttribute[@Name eq 'aid:cstyle']][idml2xml:Br]" 
    mode="idml2xml:ConsolidateParagraphStyleRanges-remove-empty">
    <xsl:variable name="context" select="." as="element(XMLElement)" />
    <xsl:for-each-group select="*[not(self::XMLAttribute)]" group-adjacent="not(self::idml2xml:Br)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <XMLElement>
            <xsl:copy-of select="$context/@*" />
            <xsl:attribute name="srcpath" select="current-group()/@srcpath" />
            <xsl:apply-templates select="current-group()" mode="#current" />
            <xsl:copy-of select="$context/XMLAttribute" />
          </XMLElement>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="#current" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>



  <!-- Paragraph grouping -->

  <xsl:template match="Table/idml2xml:Br" mode="idml2xml:ConsolidateParagraphStyleRanges" />

  <xsl:template match="*[not(self::Table or self::Group)][idml2xml:Br]" mode="idml2xml:ConsolidateParagraphStyleRanges">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:copy-of select="StoryPreference union InCopyExportOption" />
      <xsl:variable name="context" select="." as="element(*)" />
      <xsl:for-each-group select="* except (StoryPreference union InCopyExportOption)" group-adjacent="not(self::idml2xml:Br)">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:variable 
                name="styles" 
                select="for $s in current-group()/descendant-or-self::*[@AppliedParagraphStyle][idml2xml:same-scope(., $context)]/@AppliedParagraphStyle
                        return idml2xml:RemoveTypeFromStyleName(string-join(($s, ''), ''))" as="xs:string*" />
            <xsl:choose>
              <xsl:when test="count(current-group()) eq 1 and current-group()[1]/@AppliedParagraphStyle">
                <xsl:apply-templates select="current-group()" mode="#current" />
              </xsl:when>
              <xsl:when test="current-group()//*[self::idml2xml:Br][idml2xml:same-scope(., $context)]">
                <xsl:apply-templates select="current-group()" mode="#current" />
              </xsl:when>
              <xsl:when test="count(distinct-values($styles)) eq 1">
                <idml2xml:ParagraphStyleRange>
                  <xsl:attribute name="AppliedParagraphStyle" select="idml2xml:RemoveTypeFromStyleName((current-group()/descendant-or-self::*[@AppliedParagraphStyle][idml2xml:same-scope(., $context)]/@AppliedParagraphStyle)[1])" />
                  <xsl:attribute name="idml2xml:reason" select="'cp1'" />
                  <xsl:attribute name="srcpath" select="current-group()/@srcpath" />
                  <xsl:apply-templates select="current-group()" mode="idml2xml:ConsolidateParagraphStyleRanges-remove-ranges" />
                </idml2xml:ParagraphStyleRange>
              </xsl:when>
              <xsl:when test="count(current-group()//*[name() = $idml2xml:idml-content-element-names]
                                                      [idml2xml:same-scope(., $context)]
                                                    /ancestor::*[@AppliedParagraphStyle]/@AppliedParagraphStyle) eq 1">
              <!-- obsolete? -->
                <xsl:apply-templates select="current-group()" mode="#current" />
              </xsl:when>
              <xsl:when test="count(distinct-values($styles)) gt 1">
                <idml2xml:ParagraphStyleRange>
                  <xsl:attribute name="AppliedParagraphStyle" select="$styles" separator=";"/>
                  <xsl:attribute name="AppliedParagraphStyleCount" select="count(distinct-values($styles))"/>
                  <xsl:attribute name="idml2xml:reason" select="'cp2'" />
                  <xsl:apply-templates select="current-group()" mode="#current" />
                </idml2xml:ParagraphStyleRange>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="#current" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <idml2xml:parsep/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@AppliedParagraphStyle]" mode="idml2xml:ConsolidateParagraphStyleRanges-remove-ranges">
    <xsl:apply-templates mode="idml2xml:ConsolidateParagraphStyleRanges" />
  </xsl:template>

</xsl:stylesheet>
