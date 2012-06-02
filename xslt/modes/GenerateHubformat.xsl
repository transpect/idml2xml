<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
    version="2.0"
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs = "http://www.w3.org/2001/XMLSchema"
    xmlns:xhtml = "http://www.w3.org/1999/xhtml"
    xmlns:css="http://www.w3.org/1996/css"
    xmlns:aid = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5 = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml = "http://www.le-tex.de/namespace/idml2xml"
    xmlns:dbk = "http://docbook.org/ns/docbook"
    exclude-result-prefixes = "#all"
    xmlns="http://docbook.org/ns/docbook"
    >

  <!-- 
       xmlns:hub	= "http://www.le-tex.de/namespace/hubformat"
       xmlns="http://www.le-tex.de/namespace/hubformat"
  -->

  <xsl:variable 
      name="hubformat-elementnames-whitelist"
      select="('anchor', 'book', 'para', 'informaltable', 'table', 'tgroup', 
               'colspec', 'tbody', 'row', 'entry', 'mediaobject', 'tab', 
               'imageobject', 'imagedata', 'phrase', 'emphasis', 'sidebar',
               'link', 'xref')"/>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-add-properties -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="idml2xml:doc" mode="idml2xml:XML-Hubformat-add-properties">
    <book xmlns="http://docbook.org/ns/docbook" version="5.1-variant le-tex_Hub-1.0" css:version="3.0-variant le-tex_Hub-1.0">
      <info>
        <keywordset role="hub">
          <keyword role="formatting-deviations-only">true</keyword>
          <keyword role="source-type">idml</keyword>
        </keywordset>
        <styles>
          <parastyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid:pstyle) return concat('ParagraphStyle', '/', $s))" mode="#current" />
          </parastyles>
          <inlinestyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid:cstyle) return concat('CharacterStyle', '/', $s))" mode="#current" />
          </inlinestyles>
        </styles>
      </info>
      <xsl:apply-templates mode="#current"/>
    </book>
  </xsl:template>

  <xsl:template match="ParagraphStyle | CharacterStyle" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:param name="wrap-in-style-element" select="true()" as="xs:boolean"/>
    <xsl:variable name="atts" as="attribute(*)*">
      <xsl:apply-templates select="if (Properties/BasedOn) 
                                   then key('idml2xml:style', Properties/BasedOn) 
                                   else ()" mode="#current">
        <xsl:with-param name="wrap-in-style-element" select="false()"/>
      </xsl:apply-templates>
      <xsl:variable name="mergeable-atts" as="attribute(*)*">
        <xsl:apply-templates select="@*, Properties/*[not(self::BasedOn)]" mode="#current" />
      </xsl:variable>
      <xsl:for-each-group select="$mergeable-atts" group-by="name()">
        <xsl:attribute name="{current-grouping-key()}" select="current-group()" />
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$wrap-in-style-element">
        <style role="{idml2xml:StyleName(@Name)}">
          <xsl:sequence select="$atts" />
        </style>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$atts" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="Properties" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  <xsl:template match="Properties/BasedOn" mode="idml2xml:XML-Hubformat-add-properties" />

  <!-- 
remap and output indesign attribute+property settings to hub format
see: idml/_IDML_Schema_RelaxNGCompact
http://cssdk.host.adobe.com/sdk/1.5/docs/WebHelp/references/csawlib/com/adobe/csawlib/CSEnumBase.html or
http://wwwimages.adobe.com/www.adobe.com/content/dam/Adobe/en/devnet/indesign/cs55-docs/IDML/idml-specification.pdf
  -->
  <xsl:template match="@* | Properties/*" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:variable name="prop" select="key('idml2xml:prop', name(), $idml2xml:propmap)" />
    <xsl:apply-templates select="$prop" mode="#current">
      <xsl:with-param name="val" select="." tunnel="yes" />
    </xsl:apply-templates>
    <xsl:if test="empty($prop)">
      <xsl:attribute name="css:_idml-{local-name()}" select="." />
    </xsl:if>
  </xsl:template>

  <xsl:template match="prop" mode="idml2xml:XML-Hubformat-add-properties" as="node()*">
    <xsl:variable name="atts" as="attribute(*)*">
      <xsl:apply-templates select="@type, val" mode="#current" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="empty($atts) and @default">
        <xsl:attribute name="css:{@target-name}" select="@default" />
      </xsl:when>
      <xsl:when test="empty($atts)" />
      <xsl:otherwise>
        <xsl:sequence select="$atts" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="val" mode="idml2xml:XML-Hubformat-add-properties" as="attribute(*)?">
    <xsl:apply-templates select="@eq, @match" mode="#current" />
  </xsl:template>

  <xsl:key name="idml2xml:color" match="idPkg:Graphic/Color" use="@Self" />

  <xsl:template match="prop/@type" mode="idml2xml:XML-Hubformat-add-properties" as="node()?">
    <xsl:param name="val" as="node()" tunnel="yes" />
    <xsl:choose>
      <xsl:when test=". eq 'passthru'">
        <xsl:attribute name="{../@name}" select="$val" />
      </xsl:when>
      <xsl:when test=". eq 'linear'">
        <xsl:attribute name="css:{../@target-name}" select="$val" />
      </xsl:when>
      <xsl:when test=". eq 'color'">
        <xsl:attribute name="css:{../@target-name}">
          <xsl:apply-templates select="key('idml2xml:color', $val, root($val))" mode="#current" />
        </xsl:attribute>
      </xsl:when>
      <xsl:when test=". eq 'length'">
        <xsl:attribute name="css:{../@target-name}" select="idml2xml:pt-length($val)" />
      </xsl:when>
      <xsl:when test=". eq 'tablist'">
        <xsl:copy-of select="$val"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="css:{../@target-name}" select="$val" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="idml2xml:pt-length" as="xs:string" >
    <xsl:param name="val" as="xs:string"/>
    <xsl:sequence select="concat(xs:string(xs:integer(xs:double($val) * 20) * 0.05), 'pt')" />
  </xsl:function>

  <xsl:template match="val/@match" mode="idml2xml:XML-Hubformat-add-properties" as="attribute(*)?">
    <xsl:param name="val" as="node()" tunnel="yes" />
    <xsl:if test="matches($val, .)">
      <xsl:call-template name="idml2xml:XML-Hubformat-atts" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="val/@eq" mode="idml2xml:XML-Hubformat-add-properties" as="attribute(*)?">
    <xsl:param name="val" as="node()" tunnel="yes" />
    <xsl:if test="$val eq .">
      <xsl:call-template name="idml2xml:XML-Hubformat-atts" />
    </xsl:if>
  </xsl:template>

  <xsl:template name="idml2xml:XML-Hubformat-atts" as="attribute(*)?">
    <xsl:variable name="target-val" select="(../@target-value, ../../@target-value)[last()]" as="xs:string?" />
    <xsl:if test="exists($target-val)">
      <xsl:attribute name="css:{(../@target-name, ../../@target-name)[last()]}" select="$target-val" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="Color" mode="idml2xml:XML-Hubformat-add-properties" as="xs:string">
    <xsl:choose>
      <xsl:when test="@Space eq 'CMYK'">
        <xsl:sequence select="concat(
                                'device-cmyk(', 
                                string-join(
                                  for $v in tokenize(@ColorValue, '\s') return xs:string(xs:double($v) * 0.01)
                                  , ','
                                ),
                                ')'
                              )" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Unknown colorspace <xsl:value-of select="@Space"/>
        </xsl:message>
        <xsl:sequence select="@ColorValue" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:key name="idml2xml:prop" match="prop" use="@name" />

  <xsl:variable name="idml2xml:propmap" as="document-node(element(propmap))">
    <xsl:document xmlns="">
      <propmap>
        <prop name="Name" />
        <prop name="NextStyle" />
        <prop name="Self" />
        <prop name="Imported" />
        <prop name="idml2xml:reason" />

        <prop name="aid:cstyle" type="passthru" />
        <prop name="aid:pstyle" type="passthru" />
        <prop name="srcpath" type="passthru" />

        <prop name="AutoLeading" implement="maybe later" />
        <prop name="BaselineShift" implement="maybe later" />
        <prop name="Composer" implement="maybe later" />
        <prop name="DropCapCharacters" implement="maybe later" />
        <prop name="DropCapLines" implement="maybe later" />
        <prop name="HorizontalScale" implement="maybe later"/>
        <prop name="Hyphenation" implement="maybe later" />
        <prop name="HyphenateAfterFirst" implement="maybe later" />
        <prop name="HyphenateBeforeLast" implement="maybe later" />
        <prop name="HyphenateCapitalizedWords" implement="maybe later" />
        <prop name="HyphenateLadderLimit" implement="maybe later" />
        <prop name="HyphenateWordsLongerThan" implement="maybe later" />
        <prop name="HyphenationZone" implement="maybe later" />
        <prop name="KerningMethod" implement="maybe later" />
        <prop name="Ligatures" implement="maybe later" />
        <prop name="NoBreak" implement="maybe later" />

        <prop name="PageNumberType" implement="maybe later" />
        <prop name="PreviewColor" implement="maybe later" />
        <prop name="StrokeColor" implement="maybe later" />
        <prop name="StrokeWeight" implement="maybe later" />
        <prop name="Tracking" implement="maybe later" />
        <prop name="VerticalScale" implement="maybe later" />
        <prop name="OTFFigureStyle" implement="maybe later" />
        <prop name="DesiredWordSpacing" implement="maybe later" />
        <prop name="MaximumWordSpacing" implement="maybe later" />
        <prop name="MinimumWordSpacing" implement="maybe later" />
        <prop name="DesiredLetterSpacing" implement="maybe later" />
        <prop name="MaximumLetterSpacing" implement="maybe later" />
        <prop name="MinimumLetterSpacing" implement="maybe later" />
        <prop name="DesiredGlyphScaling" implement="maybe later" />
        <prop name="MaximumGlyphScaling" implement="maybe later" />
        <prop name="MinimumGlyphScaling" implement="maybe later" />
        <prop name="StartParagraph" implement="maybe later" />
        <prop name="KeepAllLinesTogether" implement="maybe later" />
        <prop name="KeepWithNext" implement="maybe later" />
        <prop name="KeepFirstLines" implement="maybe later" />
        <prop name="KeepLastLines" implement="maybe later" />
        <prop name="Position" implement="maybe later" />
        <prop name="CharacterAlignment" implement="maybe later" />
        <prop name="KeepLinesTogether" implement="maybe later" />
        <prop name="StrokeTint" implement="maybe later" />
        <prop name="FillTint" implement="maybe later" />
        <prop name="OverprintStroke" implement="maybe later" />
        <prop name="OverprintFill" implement="maybe later" />
        <prop name="GradientStrokeAngle" implement="maybe later" />
        <prop name="GradientFillAngle" implement="maybe later" />
        <prop name="GradientStrokeLength" implement="maybe later" />
        <prop name="GradientFillLength" implement="maybe later" />
        <prop name="GradientStrokeStart" implement="maybe later" />
        <prop name="GradientFillStart" implement="maybe later" />
        <prop name="Skew" implement="maybe later" />
        <prop name="RuleAboveLineWeight" implement="maybe later" />
        <prop name="RuleAboveTint" implement="maybe later" />
        <prop name="RuleAboveOffset" implement="maybe later" />
        <prop name="RuleAboveLeftIndent" implement="maybe later" />
        <prop name="RuleAboveRightIndent" implement="maybe later" />
        <prop name="RuleAboveWidth" implement="maybe later" />
        <prop name="RuleBelowLineWeight" implement="maybe later" />
        <prop name="RuleBelowTint" implement="maybe later" />
        <prop name="RuleBelowOffset" implement="maybe later" />
        <prop name="RuleBelowLeftIndent" implement="maybe later" />
        <prop name="RuleBelowRightIndent" implement="maybe later" />
        <prop name="RuleBelowWidth" implement="maybe later" />
        <prop name="RuleAboveOverprint" implement="maybe later" />
        <prop name="RuleBelowOverprint" implement="maybe later" />
        <prop name="RuleAbove" implement="maybe later" />
        <prop name="RuleBelow" implement="maybe later" />
        <prop name="LastLineIndent" implement="maybe later" />
        <prop name="HyphenateLastWord" implement="maybe later" />
        <prop name="ParagraphBreakType" implement="maybe later" />
        <prop name="SingleWordJustification" implement="maybe later" />
        <prop name="OTFOrdinal" implement="maybe later" />
        <prop name="OTFFraction" implement="maybe later" />
        <prop name="OTFDiscretionaryLigature" implement="maybe later" />
        <prop name="OTFTitling" implement="maybe later" />
        <prop name="RuleAboveGapTint" implement="maybe later" />
        <prop name="RuleAboveGapOverprint" implement="maybe later" />
        <prop name="RuleBelowGapTint" implement="maybe later" />
        <prop name="RuleBelowGapOverprint" implement="maybe later" />
        <prop name="DropcapDetail" implement="maybe later" />
        <prop name="PositionalForm" implement="maybe later" />
        <prop name="OTFMark" implement="maybe later" />
        <prop name="HyphenWeight" implement="maybe later" />
        <prop name="OTFLocale" implement="maybe later" />
        <prop name="HyphenateAcrossColumns" implement="maybe later" />
        <prop name="KeepRuleAboveInFrame" implement="maybe later" />
        <prop name="IgnoreEdgeAlignment" implement="maybe later" />
        <prop name="OTFSlashedZero" implement="maybe later" />
        <prop name="OTFStylisticSets" implement="maybe later" />
        <prop name="OTFHistorical" implement="maybe later" />
        <prop name="OTFContextualAlternate" implement="maybe later" />
        <prop name="UnderlineGapOverprint" implement="maybe later" />
        <prop name="UnderlineGapTint" implement="maybe later" />
        <prop name="UnderlineOffset" implement="maybe later" />
        <prop name="UnderlineOverprint" implement="maybe later" />
        <prop name="UnderlineTint" implement="maybe later" />
        <prop name="UnderlineWeight" implement="maybe later" />
        <prop name="StrikeThroughGapOverprint" implement="maybe later" />
        <prop name="StrikeThroughGapTint" implement="maybe later" />
        <prop name="StrikeThroughOffset" implement="maybe later" />
        <prop name="StrikeThroughOverprint" implement="maybe later" />
        <prop name="StrikeThroughTint" implement="maybe later" />
        <prop name="StrikeThroughWeight" implement="maybe later" />
        <prop name="MiterLimit" implement="maybe later" />
        <prop name="StrokeAlignment" implement="maybe later" />
        <prop name="EndJoin" implement="maybe later" />
        <prop name="OTFSwash" implement="maybe later" />
        <prop name="Tsume" implement="maybe later" />
        <prop name="LeadingAki" implement="maybe later" />
        <prop name="TrailingAki" implement="maybe later" />
        <prop name="KinsokuType" implement="maybe later" />
        <prop name="KinsokuHangType" implement="maybe later" />
        <prop name="BunriKinshi" implement="maybe later" />
        <prop name="RubyOpenTypePro" implement="maybe later" />
        <prop name="RubyFontSize" implement="maybe later" />
        <prop name="RubyAlignment" implement="maybe later" />
        <prop name="RubyType" implement="maybe later" />
        <prop name="RubyParentSpacing" implement="maybe later" />
        <prop name="RubyXScale" implement="maybe later" />
        <prop name="RubyYScale" implement="maybe later" />
        <prop name="RubyXOffset" implement="maybe later" />
        <prop name="RubyYOffset" implement="maybe later" />
        <prop name="RubyPosition" implement="maybe later" />
        <prop name="RubyAutoAlign" implement="maybe later" />
        <prop name="RubyParentOverhangAmount" implement="maybe later" />
        <prop name="RubyOverhang" implement="maybe later" />
        <prop name="RubyAutoScaling" implement="maybe later" />
        <prop name="RubyParentScalingPercent" implement="maybe later" />
        <prop name="RubyTint" implement="maybe later" />
        <prop name="RubyOverprintFill" implement="maybe later" />
        <prop name="RubyStrokeTint" implement="maybe later" />
        <prop name="RubyOverprintStroke" implement="maybe later" />
        <prop name="RubyWeight" implement="maybe later" />
        <prop name="KentenKind" implement="maybe later" />
        <prop name="KentenFontSize" implement="maybe later" />
        <prop name="KentenXScale" implement="maybe later" />
        <prop name="KentenYScale" implement="maybe later" />
        <prop name="KentenPlacement" implement="maybe later" />
        <prop name="KentenAlignment" implement="maybe later" />
        <prop name="KentenPosition" implement="maybe later" />
        <prop name="KentenCustomCharacter" implement="maybe later" />
        <prop name="KentenCharacterSet" implement="maybe later" />
        <prop name="KentenTint" implement="maybe later" />
        <prop name="KentenOverprintFill" implement="maybe later" />
        <prop name="KentenStrokeTint" implement="maybe later" />
        <prop name="KentenOverprintStroke" implement="maybe later" />
        <prop name="KentenWeight" implement="maybe later" />
        <prop name="Tatechuyoko" implement="maybe later" />
        <prop name="TatechuyokoXOffset" implement="maybe later" />
        <prop name="TatechuyokoYOffset" implement="maybe later" />
        <prop name="AutoTcy" implement="maybe later" />
        <prop name="AutoTcyIncludeRoman" implement="maybe later" />
        <prop name="Jidori" implement="maybe later" />
        <prop name="GridGyoudori" implement="maybe later" />
        <prop name="GridAlignFirstLineOnly" implement="maybe later" />
        <prop name="GridAlignment" implement="maybe later" />
        <prop name="CharacterRotation" implement="maybe later" />
        <prop name="RotateSingleByteCharacters" implement="maybe later" />
        <prop name="Rensuuji" implement="maybe later" />
        <prop name="ShataiMagnification" implement="maybe later" />
        <prop name="ShataiDegreeAngle" implement="maybe later" />
        <prop name="ShataiAdjustTsume" implement="maybe later" />
        <prop name="ShataiAdjustRotation" implement="maybe later" />
        <prop name="Warichu" implement="maybe later" />
        <prop name="WarichuLines" implement="maybe later" />
        <prop name="WarichuSize" implement="maybe later" />
        <prop name="WarichuLineSpacing" implement="maybe later" />
        <prop name="WarichuAlignment" implement="maybe later" />
        <prop name="WarichuCharsBeforeBreak" implement="maybe later" />
        <prop name="WarichuCharsAfterBreak" implement="maybe later" />
        <prop name="OTFHVKana" implement="maybe later" />
        <prop name="OTFProportionalMetrics" implement="maybe later" />
        <prop name="OTFRomanItalics" implement="maybe later" />
        <prop name="LeadingModel" implement="maybe later" />
        <prop name="ScaleAffectsLineHeight" implement="maybe later" />
        <prop name="ParagraphGyoudori" implement="maybe later" />
        <prop name="CjkGridTracking" implement="maybe later" />
        <prop name="GlyphForm" implement="maybe later" />
        <prop name="RubyAutoTcyDigits" implement="maybe later" />
        <prop name="RubyAutoTcyIncludeRoman" implement="maybe later" />
        <prop name="RubyAutoTcyAutoScale" implement="maybe later" />
        <prop name="TreatIdeographicSpaceAsSpace" implement="maybe later" />
        <prop name="AllowArbitraryHyphenation" implement="maybe later" />

        <prop name="BulletsAndNumberingListType" implement="maybe later" />
        <prop name="NumberingStartAt" implement="maybe later" />
        <prop name="NumberingLevel" implement="maybe later" />
        <prop name="NumberingContinue" implement="maybe later" />
        <prop name="NumberingApplyRestartPolicy" implement="maybe later" />
        <prop name="BulletsAlignment" implement="maybe later" />
        <prop name="NumberingAlignment" implement="maybe later" />
        <prop name="NumberingExpression" implement="maybe later" />
        <prop name="BulletsTextAfter" implement="maybe later" />
        <prop name="DigitsType" implement="maybe later" />
        <prop name="Kashidas" implement="maybe later" />
        <prop name="DiacriticPosition" implement="maybe later" />
        <prop name="ParagraphDirection" implement="maybe later" />
        <prop name="ParagraphJustification" implement="maybe later" />

        <prop name="XOffsetDiacritic" implement="maybe later" />
        <prop name="YOffsetDiacritic" implement="maybe later" />
        <prop name="OTFOverlapSwash" implement="maybe later" />
        <prop name="OTFStylisticAlternate" implement="maybe later" />
        <prop name="OTFJustificationAlternate" implement="maybe later" />
        <prop name="OTFStretchedAlternate" implement="maybe later" />
        <prop name="KeyboardDirection" implement="maybe later" />
        <prop name="KeyboardShortcut" implement="maybe later" />
        <prop name="Leading" implement="maybe later" />
        <prop name="RuleAboveColor" implement="maybe later" />
        <prop name="RuleBelowColor" implement="maybe later" />
        <prop name="RuleAboveType" implement="maybe later" />
        <prop name="RuleBelowType" implement="maybe later" />
        <prop name="BalanceRaggedLines" implement="maybe later" />
        <prop name="RuleAboveGapColor" implement="maybe later" />
        <prop name="RuleBelowGapColor" implement="maybe later" />
        <prop name="UnderlineColor" implement="maybe later" />
        <prop name="UnderlineGapColor" implement="maybe later" />

        <prop name="StrikeThroughColor" implement="maybe later" />
        <prop name="StrikeThroughGapColor" implement="maybe later" />
        <prop name="StrikeThroughType" implement="maybe later" />
        <prop name="Mojikumi" implement="maybe later" />
        <prop name="KinsokuSet" implement="maybe later" />
        <prop name="RubyFont" implement="maybe later" />
        <prop name="RubyFontStyle" implement="maybe later" />
        <prop name="RubyFill" implement="maybe later" />
        <prop name="RubyStroke" implement="maybe later" />
        <prop name="KentenFont" implement="maybe later" />
        <prop name="KentenFontStyle" implement="maybe later" />
        <prop name="KentenFillColor" implement="maybe later" />
        <prop name="KentenStrokeColor" implement="maybe later" />
        <prop name="BulletChar" implement="maybe later" />
        <prop name="NumberingFormat" implement="maybe later" />
        <prop name="BulletsFont" implement="maybe later" />
        <prop name="BulletsFontStyle" implement="maybe later" />
        <prop name="AppliedNumberingList" implement="maybe later" />
        <prop name="NumberingRestartPolicies" implement="maybe later" />
        <prop name="BulletsCharacterStyle" implement="maybe later" />
        <prop name="NumberingCharacterStyle" implement="maybe later" />


        <prop name="AppliedFont" type="linear" target-name="font-family"/>
        <prop name="AppliedLanguage" implement="maybe later" />
        <prop name="Capitalization" target-name="text-transform">
          <val eq="SmallCaps" target-name="font-variant" target-value="smallcaps"/>
          <val eq="AllCaps" target-name="text-transform" target-value="uppercase"/>
          <val eq="CapToSmallCap" target-name="text-transform" target-value="uppercase"/><!-- ? -->
        </prop>
        <prop name="CharacterDirection" target-name="text-direction">
          <!-- string "DefaultDirection" | string "LeftToRightDirection" | 
               string "RightToLeftDirection" -->
          <val eq="LeftToRightDirection" target-value="ltr"/>
          <val eq="RightToLeftDirection" target-value="rtl"/>
        </prop>
        <prop name="FillColor" type="color" target-name="color" />
        <prop name="FirstLineIndent" type="length" target-name="text-indent" />
        <prop name="FontStyle">
          <val match="Condensed" target-name="font-stretch" target-value="condensed" />
          <val match="Italic" target-name="font-style" target-value="italic" />
          <val match="Medium" target-name="font-weight" target-value="normal" />
          <val match="Regular" target-name="font-weight" target-value="400" />
          <val match="Roman" target-name="font-weight" target-value="400" />
        </prop>
        <prop name="Justification">
          <!-- string "LeftAlign" | string "CenterAlign" | string "RightAlign" | 
               string "LeftJustified" | string "RightJustified" | 
               string "CenterJustified" | string "FullyJustified" | 
               string "ToBindingSide" | string "AwayFromBindingSide" -->
          <val match="LeftAlign" target-name="text-align" target-value="left" />
          <val match="ToBindingSide" target-name="text-align" target-value="left" />
          <val match="AwayFromBindingSide" target-name="text-align" target-value="right" />
          <val match="RightAlign" target-name="text-align" target-value="right" />
          <val match="CenterAlign" target-name="text-align" target-value="center" />
          <val match="Justified" target-name="text-align" target-value="justify" />
          <val match="LeftJustified" target-name="text-align-last" target-value="left" />
          <val match="RightJustified" target-name="text-align-last" target-value="right" />
          <val match="CenterJustified" target-name="text-align-last" target-value="center" />
          <val match="FullyJustified" target-name="text-align-last" target-value="justify" />
        </prop>
        <prop name="LeftIndent" type="length" target-name="margin-left" />
        <prop name="ParagraphDirection" target-name="text-direction">
          <!-- string | string "LeftToRightDirection" | string "RightToLeftDirection" -->
          <val eq="RightToLeftDirection" target-value="rtl"/>
        </prop>
        <prop name="PointSize" type="length" target-name="font-size" />
        <prop name="RightIndent" type="length" target-name="margin-right" />
        <prop name="ShadowColor" type="color" target-name="_hub-shadow-color" />
        <prop name="SpaceAfter" type="length" target-name="margin-bottom" />
        <prop name="SpaceBefore" type="length" target-name="margin-top" />
        <prop name="StrikeThru" target-name="text-decoration">
          <val eq="true" target-value="line-through"/>
          <val eq="false"/>
        </prop>
        <prop name="TabList" type="list" target-name="text-decoration"/>
        <prop name="Underline" target-name="text-decoration">
          <val eq="true" target-value="underline"/>
          <val eq="false"/>
        </prop>
        <prop name="UnderlineType" implement="use text-decoration-style must look at Stroke/..." />
      </propmap>
    </xsl:document>
  </xsl:variable>


  <xsl:template match="idPkg:Styles | idPkg:Graphic | idml2xml:hyper" mode="idml2xml:XML-Hubformat-add-properties" />

  <xsl:key name="idml2xml:style" 
    match="CellStyle | CharacterStyle | ObjectStyle | ParagraphStyle | TableStyle" 
    use="@Self" />


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-extract-frames -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- must handle frames in frames! -->
  <xsl:template match="*[@*:pstyle or @*:AppliedParagraphStyle][.//idml2xml:genFrame[idml2xml:same-scope(., current())]]" mode="idml2xml:XML-Hubformat-extract-frames">
    <xsl:variable name="frames" as="element(idml2xml:genFrame)+">
      <xsl:sequence select=".//idml2xml:genFrame[idml2xml:same-scope(., current())]"/>
    </xsl:variable>
    <xsl:variable name="frames-after-text" select="$frames[not(idml2xml:text-after(., current()))]" as="element(idml2xml:genFrame)*" />
    <xsl:apply-templates select="$frames except $frames-after-text"  mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
    <xsl:apply-templates select="$frames-after-text"  mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
  </xsl:template>

  <xsl:function name="idml2xml:text-after" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:param name="ancestor" as="element(*)" />
    <xsl:sequence select="matches(
                            string-join($ancestor//text()[. &gt;&gt; $elt] except $ancestor//idml2xml:genFrame//text(), ''),
                            '\S'
                          )" />
  </xsl:function>

  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames">
    <idml2xml:genAnchor id="{generate-id()}"/>
  </xsl:template>

  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames-genFrame">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="linkend" select="generate-id()" />
      <xsl:apply-templates mode="idml2xml:XML-Hubformat-extract-frames" />
    </xsl:copy>
  </xsl:template>


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-remap-para-and-span -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


  <xsl:variable name="id-prefix" select="'id_'" as="xs:string"/>

  <xsl:template match="idml2xml:genPara" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable 
        name="style" select="if (@aid:pstyle ne '') then @aid:pstyle else 'Standard'"
        as="xs:string"/>
    <para>
      <xsl:attribute name="role" select="idml2xml:StyleName( $style )" />
      <xsl:apply-templates select="@* except (@pstyle|@aid:pstyle )" mode="#current"/>
      <xsl:if test="HyperlinkTextDestination[1]/@DestinationUniqueKey ne ''">
        <xsl:attribute name="xml:id" select="concat ($id-prefix, HyperlinkTextDestination[1]/@DestinationUniqueKey)"/>
      </xsl:if>
      <!-- set anchor for hyperlink -->
      <xsl:if test="count (HyperlinkTextDestination) gt 1">
        <xsl:for-each select="HyperlinkTextDestination[position() ne 1]/@DestinationUniqueKey">
          <phrase xml:id="{concat ($id-prefix,.)}"/>
        </xsl:for-each>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </para>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[
                         not(
                           (
                             exists(Rectangle)
                             or
                             exists(idml2xml:genFrame)
                           ) 
                           or 
                           @aid:table = ('table')
                         )
                       ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="role" select="idml2xml:StyleName( @aid:cstyle )"/>
    <xsl:choose>
      <xsl:when test="$role = ('Nocharacterstyle', 'idml2xml:default') and not(text()[matches(., '\S')]) and count(*) gt 0 and count(*) eq count(PageReference union HyperlinkTextSource)">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:when test="$role = ('Nocharacterstyle', 'idml2xml:default') and not(text()[matches(., '\S')]) and count(* except idml2xml:genAnchor) eq 0">
        <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
      </xsl:when>
      <xsl:when test="$role = ('Nocharacterstyle', 'idml2xml:default') and text() and count(* except idml2xml:genAnchor) eq 0">
        <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        <xsl:apply-templates select="node() except idml2xml:genAnchor" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="idml2xml:genAnchor">
          <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        </xsl:if>
        <phrase role="{$role}">
          <xsl:variable name="emph-atts" as="attribute(*)*">
            <xsl:apply-templates select="@* except @aid:cstyle" mode="#current"/>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="exists($emph-atts)">
              <emphasis>
                <xsl:sequence select="$emph-atts" />
                <xsl:apply-templates select="node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
              </emphasis>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </phrase>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="idml2xml:link" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <link>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </link>
  </xsl:template>

  <xsl:template match="idml2xml:xref" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xref>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </xref>
  </xsl:template>

  <xsl:template match="idml2xml:genAnchor" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor id="{$id-prefix}{@*:id}" />
  </xsl:template>

  <xsl:template match="@linkend" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="linkend" select="concat ($id-prefix, .)" />
  </xsl:template>

  <xsl:template match="idml2xml:genFrame" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <sidebar remap="{@idml2xml:elementName}">
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </sidebar>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[ not( descendant::node()[self::text()] ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"
		priority="-1">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- May this be safely discarded under any circumstance? -->
  <xsl:template match="TextVariableInstance" mode="idml2xml:XML-Hubformat-remap-para-and-span" />


<!--  <xsl:template match="idml2xml:CharacterStyleRange[ ( idml2xml:Br  and  count(*) eq 1 )  or  
		       ( idml2xml:Br  and  idml2xml:Content 	and  not( idml2xml:Content/node() )
		       and count(*) eq 2 ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:if test="not( following::*[1][ self::idml2xml:ParagraphStyleRange ] )">
      <xsl:apply-templates mode="#current"/>
    </xsl:if>
  </xsl:template>-->

  <xsl:template match="PageReference" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <indexterm>
    <xsl:for-each select="tokenize( @ReferencedTopic, '(d1)?Topicn' )">
      <xsl:choose>
	<xsl:when test="position() eq 1  or  current() eq ''"/>
	<xsl:when test="position() eq 2">
	  <primary>
	    <xsl:value-of select="current()"/>
	  </primary>
	</xsl:when>
	<xsl:when test="position() eq 3">
	  <secondary>
	    <xsl:value-of select="current()"/>
	  </secondary>
	</xsl:when>
	<xsl:when test="position() eq 4">
	  <tertiary>
	    <xsl:value-of select="current()"/>
	  </tertiary>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message select="'WARNING: PageReference / sub-indexterm not processed:', ."/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </indexterm>
  </xsl:template>
  
  <xsl:template match="idml2xml:newline"
    mode="idml2xml:XML-Hubformat-remap-para-and-span" />
  
  <xsl:template match="	Root |
		       idml2xml:Content | 
		       idml2xml:Document | 
		       idml2xml:genDoc |
		       idml2xml:InCopyExportOption |
		       idml2xml:Story | 
		       idml2xml:StoryPreference
		       " mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="idml2xml:genDoc[ node() ]
                       [ not (descendant::*[local-name() eq 'genPara']) and
                         preceding-sibling::*[1][self::idml2xml:newline] and
                         following-sibling::*[1][self::idml2xml:newline]
                       ]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <para>
      <xsl:attribute 
          name="role" 
          select="if (preceding::*[self::idml2xml:genPara])
                  then preceding::*[self::idml2xml:genPara][1]/@aid:pstyle
                  else following::*[self::idml2xml:genPara][1]/@aid:pstyle"/>
      <xsl:apply-templates mode="#current"/>
    </para>
  </xsl:template>

  <xsl:template match="idml2xml:ParagraphStyleRange[
                       count(*) eq 1 and idml2xml:genPara
                       ]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

<!--  <xsl:template match="idml2xml:genPara[@aid:pstyle='Bild']"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    
  </xsl:template>-->

  <xsl:template 
    match="@idml2xml:* " 
    mode="idml2xml:XML-Hubformat-remap-para-and-span" 
    />

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-remap-para-and-span" >
    <xsl:copy-of select="." />
  </xsl:template>


  <!-- BEGIN: tables -->

  <xsl:template match="idml2xml:*[*[@aid:table='table']]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="cell-src-name" select="'genCell'" />
    <xsl:variable name="colspan-src-name" select="'ccols'" />
    <xsl:variable name="rowspan-src-name" select="'crows'" />
    <xsl:variable name="var-cols" select="xs:integer(idml2xml:genSpan[@aid:table='table']/@aid:tcols)" />
    <xsl:variable name="var-table">
      <xsl:for-each select="idml2xml:make-rows( $var-cols, 
			    descendant::*[local-name()=$cell-src-name][1], 
			    number(descendant::*[local-name()=$cell-src-name][1]/@*[local-name()=$colspan-src-name]), 
			    0, 
			    'true',
			    $cell-src-name,
			    $colspan-src-name,
			    $rowspan-src-name
			    )/descendant-or-self::*:row">
	<xsl:copy>
	  <xsl:sequence select="*[local-name()=$cell-src-name]" />
	</xsl:copy>
      </xsl:for-each>
    </xsl:variable>
    <xsl:element name="informaltable">
      <xsl:element name="tgroup">
	<xsl:attribute name="cols" select="$var-cols" />
	<xsl:for-each select="1 to $var-cols">
	  <xsl:element name="colspec">
	    <xsl:attribute name="colname" select="concat( 'c', current() )"/>
	  </xsl:element>
	</xsl:for-each>
	<xsl:element name="tbody">
	    <xsl:apply-templates select="$var-table" mode="#current" />
	</xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="idml2xml:genCell[@aid:table='cell']" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="cumulated-cols" select="xs:integer(@cumulated-cols)" />
    <xsl:variable name="colspan" select="xs:integer(@aid:ccols)" />
    <xsl:variable name="rowspan" select="xs:integer(@aid:crows)" />
    <entry>
      <xsl:if test="$colspan=1">
	<xsl:attribute name="colname" select="concat('c', $cumulated-cols - $colspan + 1)" />
      </xsl:if>
      <xsl:if test="$colspan gt 1">
	<xsl:attribute name="namest" select="concat('c', $cumulated-cols - $colspan + 1)" />
	<xsl:attribute name="nameend" select="concat('c', $cumulated-cols)" />
      </xsl:if>
      <xsl:if test="$rowspan gt 1">
	<xsl:attribute name="morerows" select="$rowspan - 1" />
      </xsl:if>
      <xsl:attribute name="role" select="@aid:pstyle"/>
      <xsl:apply-templates mode="#current"/>
    </entry>
  </xsl:template>
  
  <xsl:function name="idml2xml:make-rows">
    <xsl:param name="var-cols" as="xs:double" />
    <xsl:param name="var-current-cell" as="element()*" />
    <xsl:param name="var-cumulated-cols" as="xs:double" />
    <xsl:param name="var-overlap" as="xs:integer*" />
    <xsl:param name="var-starts" as="xs:string" />
    <xsl:param name="cell-src-name" as="xs:string" />
    <xsl:param name="colspan-src-name" as="xs:string" />
    <xsl:param name="rowspan-src-name" as="xs:string" />
    <xsl:variable name="var-new-overlap" as="xs:integer*">
      <xsl:choose>
	<xsl:when test="$var-starts = 'false'">
	  <xsl:for-each select="subsequence($var-overlap, 1)">
	    <xsl:variable name="decrement" select=". - 1" as="xs:integer"/>
	    <xsl:if test="$decrement gt 0">
	      <xsl:value-of select=". - 1" />
	    </xsl:if>
	  </xsl:for-each>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:sequence select="$var-overlap" />
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="var-cumulated-overlap" as="xs:integer*">
      <xsl:value-of select="count(subsequence($var-new-overlap, 1)[. gt 0])"/>
    </xsl:variable>
    <xsl:if test="($var-current-cell ne '') or exists($var-current-cell/following-sibling::*[local-name()=$cell-src-name])">
      <xsl:element name="row">
	<xsl:sequence select="idml2xml:cells2row($var-cols, $var-current-cell, $var-cumulated-overlap + number($var-current-cell/@*[local-name()=$colspan-src-name]), $var-new-overlap, $cell-src-name, $colspan-src-name, $rowspan-src-name)" />
      </xsl:element>
    </xsl:if>
  </xsl:function>

  <xsl:function name="idml2xml:cells2row">
    <xsl:param name="var-cols" as="xs:double" />
    <xsl:param name="var-current-cell" as="element()*" />
    <xsl:param name="var-cumulated-cols" as="xs:double" />
    <xsl:param name="var-overlap" as="xs:integer*" />
    <xsl:param name="cell-src-name" as="xs:string" />
    <xsl:param name="colspan-src-name" as="xs:string" />
    <xsl:param name="rowspan-src-name" as="xs:string" />
    <xsl:variable name="var-new-overlap" as="xs:integer*">
      <xsl:sequence select="$var-overlap, if ($var-current-cell/@*[local-name()=$rowspan-src-name] ne '1') then idml2xml:for-loop(1, xs:integer($var-current-cell/@*[local-name()=$colspan-src-name]), xs:integer($var-current-cell/@*[local-name()=$rowspan-src-name])) else 0" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$var-cumulated-cols eq $var-cols">
	<xsl:for-each select="$var-current-cell">
	  <xsl:copy>
	    <xsl:attribute name="cumulated-cols" select="$var-cumulated-cols" />
	    <xsl:copy-of select="@*|node()" />
	  </xsl:copy>
	</xsl:for-each>
	<xsl:sequence select="idml2xml:make-rows($var-cols, $var-current-cell/following-sibling::*[local-name()=$cell-src-name][1], number($var-current-cell/following-sibling::*[local-name()=$cell-src-name][1]/@*[local-name()=$colspan-src-name]), $var-new-overlap, 'false', $cell-src-name, $colspan-src-name, $rowspan-src-name)" />
      </xsl:when>
      <xsl:when test="$var-cumulated-cols lt $var-cols">
	<xsl:for-each select="$var-current-cell">
	  <xsl:copy>
	    <xsl:attribute name="cumulated-cols" select="$var-cumulated-cols" />
	    <xsl:copy-of select="@*|node()" />
	  </xsl:copy>
	</xsl:for-each>
	<xsl:sequence select="idml2xml:cells2row($var-cols, $var-current-cell/following-sibling::*[local-name()=$cell-src-name][1], $var-cumulated-cols + number($var-current-cell/following-sibling::*[local-name()=$cell-src-name][1]/@*[local-name()=$colspan-src-name]), $var-new-overlap, $cell-src-name, $colspan-src-name, $rowspan-src-name)" />
      </xsl:when>
      <xsl:when test="$var-cumulated-cols gt $var-cols">
	<xsl:message terminate="no">Error: <xsl:value-of select="$var-cumulated-cols" /> cells in row, but only <xsl:value-of select="$var-cols" /> are allowed.</xsl:message>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="idml2xml:for-loop">
    <xsl:param name="from" as="xs:integer" />
    <xsl:param name="to" as="xs:integer" />
    <xsl:param name="do" />
    <xsl:choose>
      <xsl:when test="$from eq $to">
	<xsl:sequence select="$do" />
      </xsl:when>
      <xsl:otherwise>
	<xsl:sequence select="$do" />
	<xsl:sequence select="idml2xml:for-loop($from, $to - 1, $do)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- END: tables -->

  <xsl:template match="HyperlinkTextDestination | 
                       HyperlinkTextSource"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>


  <!-- figures -->
  <xsl:template match="Rectangle[not(@idml2xml:rectangle-embedded-source='true')]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <para>
      <mediaobject>
        <imageobject>
          <imagedata fileref="{.//@LinkResourceURI}"/>
        </imageobject>
      </mediaobject>
    </para>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[Rectangle]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="idml2xml:XmlStory" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"/>
  

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-cleanup-paras-and-br -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  <xsl:template match="phrase[ parent::p[count(*) eq 1 ] ]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="phrase[@role='br'][ following-sibling::*[ self::para ] ] |
		       phrase[@role='br'][ not(following-sibling::*) and parent::para ]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>

  <xsl:template match="row[not(node())]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:message select="'INFO: Removed empty element row.'"/>
  </xsl:template>

  <xsl:template match="para[parent::para]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <phrase role="idml2xml-para {@role}">
      <xsl:apply-templates select="@* except @role | node()" mode="#current"/>
    </phrase>
  </xsl:template>

  <xsl:template 
      match="@*:AppliedParagraphStyle | @*:AppliedCharacterStyle" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" />

  <xsl:template 
      match="*[not( local-name() = $hubformat-elementnames-whitelist )]" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:variable name="content" select="string-join(.,'')"/>
    <xsl:message>
      INFO: Removed non-hub element <xsl:value-of select="local-name()"/>
      <xsl:if test="$content ne ''">
        ===
        Text content: <xsl:value-of select="$content"/>
        ===</xsl:if>
    </xsl:message>
  </xsl:template>

</xsl:stylesheet>