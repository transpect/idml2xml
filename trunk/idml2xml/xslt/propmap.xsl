<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
    exclude-result-prefixes = "xs idPkg"
>

  <!-- The predicate prop[…] is needed when there are multiple entries with different @hubversion
    attributes. The key picks, of all prop declarations that are compatible with the requested $hub-version, 
    the prop declaration for the most recent version. Versions numbers are expected to be dot-separated integers.
    -->  
  <xsl:key 
    name="idml2xml:prop" 
    match="prop[
      if(@hubversion)
      then (
        compare($hub-version, @hubversion, 'http://saxon.sf.net/collation?alphanumeric=yes') ge 0
        and @hubversion = max(
          ../prop
            [@name = current()/@name]
            [compare($hub-version, @hubversion, 'http://saxon.sf.net/collation?alphanumeric=yes') ge 0]
              /@hubversion, 
          'http://saxon.sf.net/collation?alphanumeric=yes'
        )
      )
      else true()
    ]"
    use="@name" />

  <xsl:variable name="idml2xml:propmap" as="document-node(element(propmap))">
    <xsl:document xmlns="">
      <propmap>
        <prop name="Name" />
        <prop name="NextStyle" />
        <prop name="Self" />
        <prop name="Imported" />
        <prop name="idml2xml:reason" />
        <prop name="AllGREPStyles" />
        <prop name="AllNestedStyles" />

        <prop name="aid:cstyle" type="passthru" />
        <prop name="aid:pstyle" type="passthru" />
        <prop name="aid5:cellstyle" type="passthru" />
        <prop name="aid5:tablestyle" type="passthru" />
        <prop name="aid:table" type="passthru" />
        <prop name="aid:ccols" type="passthru" />
        <prop name="aid:crows" type="passthru" />
        <prop name="aid:tcols" type="passthru" />
        <prop name="aid:trows" type="passthru" />
        <prop name="linkend" type="passthru" />
        <prop name="remap" type="passthru" />
        <prop name="role" type="passthru" />
        <prop name="srcpath" type="passthru" />
        <prop name="idml2xml:elementName" type="passthru" />
        <prop name="LinkResourceURI" type="passthru" />

        <prop name="AppliedFont" type="linear" target-name="css:font-family"/>
        <prop name="AppliedLanguage" type="lang" target-name="xml:lang" />
        <prop name="AppliedParagraphStyle" type="style-link" />
        <prop name="BottomInset" type="length" target-name="css:padding-bottom" />
        <prop name="BulletsAndNumberingListType" target-name="list-type" type="linear" hubversion="1.0"/>
        <prop name="BulletsAndNumberingListType" target-name="css:list-style-type" type="list-type-declaration" hubversion="1.1"/>
        <prop name="BulletChar" target-name="css:pseudo-marker_content" type="bullet-char"/> 
        <prop name="Capitalization">
          <val eq="SmallCaps" target-name="css:font-variant" target-value="small-caps"/>
          <val eq="AllCaps" target-name="css:text-transform" target-value="uppercase"/>
          <val eq="CapToSmallCap" target-name="css:text-transform" target-value="uppercase"/><!-- ? -->
        </prop>
        <prop name="aid:ccolwidth" type="length" target-name="css:width"/>
        <prop name="CharacterDirection" target-name="css:direction">
          <val eq="DefaultDirection" target-value="ltr"/>
          <val eq="LeftToRightDirection" target-value="ltr"/>
          <val eq="RightToLeftDirection" target-value="rtl"/>
        </prop>
        <prop name="FillColor" type="color" target-name="css:background-color">
          <context match="Para|Char" target-name="css:color"/>
        </prop>
        <prop name="FillTint" type="percentage" target-name="fill-tint"/>
        <prop name="FirstLineIndent" type="length" target-name="css:text-indent" />
        <prop name="FontStyle">
          <val match="Condensed" target-name="css:font-stretch" target-value="condensed" />
          <val match="(^|\W)Bold" target-name="css:font-weight" target-value="bold" />
          <val match="SemiBold" target-name="css:font-weight" target-value="600" />
          <val match="Italic" target-name="css:font-style" target-value="italic" />
          <val match="Oblique" target-name="css:font-style" target-value="oblique" />
          <val match="Medium" target-name="css:font-weight" target-value="normal" />
          <val match="Regular" target-name="css:font-weight" target-value="normal" />
          <val match="Roman" target-name="css:font-weight" target-value="normal" />
        </prop>
        <prop name="Hidden" target-name="css:display">
          <val eq="true" target-value="none"/>
          <val eq="false"/>
        </prop>
        <prop name="Justification">
          <!-- string "LeftAlign" | string "CenterAlign" | string "RightAlign" | 
               string "LeftJustified" | string "RightJustified" | 
               string "CenterJustified" | string "FullyJustified" | 
               string "ToBindingSide" | string "AwayFromBindingSide" -->
          <val match="LeftAlign" target-name="css:text-align" target-value="left" />
          <val match="ToBindingSide" target-name="css:text-align" target-value="left" />
          <val match="AwayFromBindingSide" target-name="css:text-align" target-value="right" />
          <val match="RightAlign" target-name="css:text-align" target-value="right" />
          <val match="CenterAlign" target-name="css:text-align" target-value="center" />
          <val match="CenterAlign" target-name="css:text-align-last" target-value="center" />
          <val match="Justified" target-name="css:text-align" target-value="justify" />
          <val match="LeftJustified" target-name="css:text-align-last" target-value="left" />
          <val match="RightJustified" target-name="css:text-align-last" target-value="right" />
          <val match="CenterJustified" target-name="css:text-align-last" target-value="center" />
          <val match="FullyJustified" target-name="css:text-align-last" target-value="justify" />
        </prop>
        <prop name="LeftIndent" type="length" target-name="css:margin-left" />
        <prop name="LeftInset" type="length" target-name="css:padding-left" />
        <prop name="ListItem/Position" type="length" target-name="horizontal-position" /><!-- for tablists -->
        <prop name="ListItem/Alignment">
          <val match="LeftAlign" target-name="align" target-value="left" />
          <val match="CenterAlign" target-name="align" target-value="center" />
          <val match="RightAlign" target-name="align" target-value="right" />
        </prop>
        <prop name="ListItem/AlignmentCharacter" type="linear" target-name="alignment-char" />
        <prop name="ListItem/Leader" type="linear" target-name="leader" />
        <prop name="NumberingStartAt" target-name="numbering-starts-at" type="linear"/>
        <prop name="NumberingLevel" target-name="numbering-level" type="linear"/>
        <prop name="NumberingContinue" target-name="numbering-continue" type="linear"/>
        <prop name="ParagraphDirection" target-name="css:text-direction">
          <!-- string | string "LeftToRightDirection" | string "RightToLeftDirection" -->
          <val eq="RightToLeftDirection" target-value="rtl"/>
        </prop>
        <prop name="PointSize" type="length" target-name="css:font-size" />
        <prop name="Position" type="position" />
        <prop name="RightIndent" type="length" target-name="css:margin-right" />
        <prop name="RightInset" type="length" target-name="css:padding-right" />
        <prop name="ShadowColor" type="color" target-name="shadow-color" />
        <prop name="SpaceAfter" type="length" target-name="css:margin-bottom" />
        <prop name="SpaceBefore" type="length" target-name="css:margin-top" />
        <prop name="StrikeThru" target-name="css:text-decoration-line">
          <val eq="true" target-value="line-through"/>
          <val eq="false"/>
        </prop>
        <prop name="TabList" type="tablist"/>
        <prop name="TintValue" type="percentage" target-name="fill-value"/>
        <prop name="TopInset" type="length" target-name="css:padding-top" />
        <prop name="Underline" target-name="css:text-decoration-line">
          <val eq="true" target-value="underline"/>
          <val eq="false"/>
        </prop>
        <prop name="UnderlineType" implement="use text-decoration-style must look at Stroke/..." />
        <prop name="VerticalJustification">
          <val match="TopAlign" />
          <val match="CenterAlign" target-name="css:vertical-align" target-value="middle" />
          <val match="BottomAlign" target-name="css:vertical-align" target-value="bottom" />
        </prop>

        <prop name="NumberingApplyRestartPolicy" implement="maybe later" />
        <prop name="BulletsAlignment" implement="maybe later" />
        <prop name="NumberingAlignment" implement="maybe later" />
        <prop name="NumberingExpression" implement="maybe later" />
        <prop name="BulletsTextAfter" implement="maybe later" />
        <prop name="DigitsType" implement="maybe later" />


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
        <prop name="CharacterAlignment" implement="maybe later" />
        <prop name="KeepLinesTogether" implement="maybe later" />
        <prop name="StrokeTint" implement="maybe later" />
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

        <prop name="AssetURL" implement="maybe later" />
        <prop name="AssetID" implement="maybe later" />
        <prop name="LinkResourceFormat" implement="maybe later" />
        <prop name="StoredState" implement="maybe later" />
        <prop name="LinkClassID" implement="maybe later" />
        <prop name="LinkClientID" implement="maybe later" />
        <prop name="LinkResourceModified" implement="maybe later" />
        <prop name="LinkObjectModified" implement="maybe later" />
        <prop name="ShowInUI" implement="maybe later" />
        <prop name="CanEmbed" implement="maybe later" />
        <prop name="CanUnembed" implement="maybe later" />
        <prop name="CanPackage" implement="maybe later" />
        <prop name="ImportPolicy" implement="maybe later" />
        <prop name="ExportPolicy" implement="maybe later" />
        <prop name="LinkImportStamp" implement="maybe later" />
        <prop name="LinkImportModificationTime" implement="maybe later" />
        <prop name="LinkImportTime" implement="maybe later" />

        <prop name="LeftCrop" implement="maybe later" />
        <prop name="BottomCrop" implement="maybe later" />
        <prop name="TopCrop" implement="maybe later" />
        <prop name="RightCrop" implement="maybe later" />
        <prop name="FittingOnEmptyFrame" implement="maybe later" />
        <prop name="FittingAlignment" implement="maybe later" />
        <prop name="Space" implement="maybe later" />
        <prop name="Inverse" implement="maybe later" />
        <prop name="ContourType" implement="maybe later" />
        <prop name="ClippingType" implement="maybe later" />
        <prop name="ApplyPhotoshopClippingPath" implement="maybe later" />
        <prop name="StoryTitle" implement="maybe later" />
        <prop name="AnchorXoffset" implement="maybe later" />

        <prop name="ContentType" implement="maybe later" />
        <prop name="Locked" implement="maybe later" />
        <prop name="LocalDisplaySetting" implement="maybe later" />
        <prop name="GradientFillHiliteLength" implement="maybe later" />
        <prop name="GradientFillHiliteAngle" implement="maybe later" />
        <prop name="GradientStrokeHiliteLength" implement="maybe later" />
        <prop name="GradientStrokeHiliteAngle" implement="maybe later" />
        <prop name="ItemTransform" implement="maybe later" />
        <prop name="AnchorYoffset" implement="maybe later" />
        <prop name="ApplyToMasterPageOnly" implement="maybe later" />
        <prop name="TextWrapSide" implement="maybe later" />
        <prop name="TextWrapMode" implement="maybe later" />
        <prop name="IncludeInsideEdges" implement="maybe later" />
        <prop name="ContourPathName" implement="maybe later" />
        <prop name="ActualPpi" implement="maybe later" />
        <prop name="EffectivePpi" implement="maybe later" />
        <prop name="ImageRenderingIntent" implement="maybe later" />
        <prop name="LocalDisplaySetting" implement="maybe later" />
        <prop name="ImageTypeName" implement="maybe later" />
        <prop name="ItemTransform" implement="maybe later" />
        <prop name="ApplyToMasterPageOnly" implement="maybe later" />
        <prop name="TextWrapSide" implement="maybe later" />
        <prop name="TextWrapMode" implement="maybe later" />
        <prop name="IncludeInsideEdges" implement="maybe later" />
        <prop name="ContourPathName" implement="maybe later" />
        <prop name="InvertPath" implement="maybe later" />
        <prop name="IncludeInsideEdges" implement="maybe later" />
        <prop name="RestrictToFrame" implement="maybe later" />
        <prop name="UseHighResolutionImage" implement="maybe later" />
        <prop name="Threshold" implement="maybe later" />
        <prop name="Tolerance" implement="maybe later" />
        <prop name="InsetFrame" implement="maybe later" />
        <prop name="AppliedPathName" implement="maybe later" />
        <prop name="Index" implement="maybe later" />
        <prop name="AllowAutoEmbedding" implement="maybe later" />
        <prop name="AlphaChannelName" implement="maybe later" />
        <prop name="DestinationUniqueKey" implement="maybe later" />

      </propmap>
    </xsl:document>
  </xsl:variable>

</xsl:stylesheet>
