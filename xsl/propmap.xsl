<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://transpect.io/idml2xml"
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
        <prop name="idml2xml:objectstyle" type="passthru" />
        <prop name="idml2xml:layer" type="passthru" />
        <prop name="idml2xml:width" type="length" target-name="css:width"/>
        <prop name="idml2xml:position" type="linear" target-name="css:position"/>
        <prop name="idml2xml:height" type="length" target-name="css:height"/>
        <prop name="idml2xml:z-index" type="linear" target-name="css:z-index"/>
        <prop name="idml2xml:transform" type="linear" target-name="css:transform"/>
        <prop name="idml2xml:transform-origin" type="linear" target-name="css:transform-origin"/>
        <prop name="idml2xml:top" type="length" target-name="css:top"/>
        <prop name="idml2xml:left" type="length" target-name="css:left"/>
        <prop name="idml2xml:id" type="linear" target-name="xml:id"/>
        <prop name="idml2xml:condition" type="linear" target-name="condition"/>
        <prop name="idml2xml:sne" type="passthru" /><!-- StyleNameEscape -->
        <prop name="idml2xml:rst" type="passthru" /><!-- RemoveStyleType -->
        <prop name="aid:table" type="passthru" />
        <prop name="aid:ccols" type="passthru" />
        <prop name="aid:colname" type="passthru" />
        <prop name="aid:crows" type="passthru" />
        <prop name="aid:rowname" type="passthru" />
        <prop name="aid:tcols" type="passthru" />
        <prop name="aid:trows" type="passthru" />
        <prop name="linkend" type="passthru" />
        <prop name="remap" type="passthru" />
        <prop name="annotations" type="passthru" />
        <prop name="role" type="passthru" />
        <prop name="SingleColumnWidth" type="passthru"/>
        <prop name="srcpath" type="passthru" />
        <prop name="idml2xml:elementName" type="passthru" />
        <prop name="idml2xml:keep-object" type="passthru" />
        <prop name="idml2xml:idml2xml:rectangle-embedded-source" type="passthru" />
        <prop name="LinkResourceURI" type="passthru" />
        
        <prop name="AppliedConditions" type="condition" />
        <prop name="AppliedFont" type="linear" target-name="css:font-family"/>
        <!-- Using unified Language Identifiers (RFC 3066) http://www.i18nguy.com/unicode/language-identifiers.html -->
        <prop name="AppliedLanguage" type="lang" target-name="xml:lang">
          <val match="(PlaceHolder_)?Arabic$|kWRIndexGroup_ArabicAlphabet" target-value="ar" />
          <val match="bn_IN" target-value="bn-IN" />
          <val match="(IDX_)?Bulgarian" target-value="bg" />
          <val match="Catalan$" target-value="ca" />
          <val match="(IDX_)?Croatian" target-value="hr" />
          <val match="(IDX_)?Czech" target-value="cs" />
          <val match="Danish$" target-value="da-DK" />
          <val match="nl_NL_2005" target-value="nl-NL" />
          <val match="Dutch$" target-value="nl" />
          <val match="English[:]\sCanadian" target-value="en-CA" />
          <val match="English[:]\sUSA$" target-value="en-US" />
          <val match="English[:]\sUSA\sLegal" target-value="en-US-Legal" />
          <val match="English[:]\sUSA\sMedical" target-value="en-US-Medical" />
          <val match="English[:]\sUK" target-value="en-GB" />
          <val match="(IDX_)?Estonian" target-value="et" />
          <val match="Finnish$" target-value="fi-FI" />
          <val match="French$" target-value="fr-FR" />
          <val match="French[:]\sCanadian" target-value="fr-CA" />
          <val match="(PlaceHolder_)?Greek(\sMode)?|kWRIndexGroup_GreekAlphabet" target-value="el" />
          <val match="German[:]\sReformed" target-value="de-DE-1996" />
          <val match="de_DE_2006$" target-value="de-DE-2006" />
          <val match="German[:]\sTraditional" target-value="de-DE" />
          <val match="gu_IN$" target-value="gu-IN" />
          <val match="(PlaceHolder_)?Hebrew(\sMode)?|kWRIndexGroup_HebrewAlphabet" target-value="he" />
          <val match="hi_IN$" target-value="hi-IN" />
          <val match="Italian$" target-value="it-IT" />
          <val match="kn_IN$" target-value="kn-IN" />
          <val match="(IDX_)?Latvian" target-value="lv" />
          <val match="(IDX_)?Lithuanian" target-value="lt" />
          <val match="ml_IN$" target-value="ml-IN" />
          <val match="mr_IN$" target-value="mr-IN" />
          <val match="Norwegian[:]\sBokmal" target-value="nb" />
          <val match="Norwegian[:]\sNynorsk" target-value="nn" />
          <val match="or_IN$" target-value="or-IN" />
          <val match="pa_IN$" target-value="pa-IN" />
          <val match="(IDX_)?Polish" target-value="pl" />
          <val match="Portuguese$" target-value="pt-PT" />
          <val match="Portuguese[:]\sBrazilian" target-value="pt-BR" />
          <val match="Portuguese[:]\sOrthographic Agreement" target-value="pt-PT" />
          <val match="(IDX_)?Romanian" target-value="ro" />
          <val match="(IDX_)?Russian" target-value="ru-RU" />
          <val match="Swedish$" target-value="sv-SE" />
          <val match="(IDX_)?Slovak" target-value="sk" />
          <val match="(IDX_)?Slovenian" target-value="sl" />
          <val match="(IDX_)?Spanish([:]\sCastilian)?" target-value="es-ES" />
          <val match="ta_IN$" target-value="ta-IN" />
          <val match="te_IN$" target-value="te-IN" />
          <val match="(IDX_)?Turkish" target-value="tr-TR" />
          <val match="(IDX_)?Ukrainian" target-value="uk" />
          <val match="(IDX_)?Hungarian" target-value="hu" />
          <val match="\$ID/\[No [Ll]anguage\]$" target-value="" />
        </prop>
        <prop name="AppliedNumberingList" target-name="hub:numbering-family" type="numbering-family"/>
        <prop name="AppliedParagraphStyle" type="style-link" />
        <prop name="BottomInset" type="length" target-name="css:padding-bottom" />
        <prop name="BulletChar" target-name="css:pseudo-marker_content" type="bullet-char"/>
        <prop name="BulletsAndNumberingListType" target-name="list-type" type="linear" hubversion="1.0"/>
        <prop name="BulletsAndNumberingListType" target-name="css:list-style-type" type="list-type-declaration" hubversion="1.1"/>
        <prop name="BulletsFont" target-name="css:pseudo-marker_font-family" type="linear"/> 
        <prop name="BulletsFontStyle">
          <val match="(^|\W)Bold" target-name="css:pseudo-marker_font-weight" target-value="bold" />
          <val match="SemiBold" target-name="css:pseudo-marker_font-weight" target-value="600" />
          <val match="Italic" target-name="css:pseudo-marker_font-style" target-value="italic" />
          <val match="Oblique" target-name="css:pseudo-marker_font-style" target-value="oblique" />
          <val match="Medium" target-name="css:pseudo-marker_font-weight" target-value="normal" />
          <val match="Regular" target-name="css:pseudo-marker_font-weight" target-value="normal" />
          <val match="Roman" target-name="css:pseudo-marker_font-weight" target-value="normal" />
          <val match="Black|Heavy" target-name="css:pseudo-marker_font-weight" target-value="900" />
        </prop>
        <prop name="Capitalization">
          <val eq="SmallCaps" target-name="css:font-variant" target-value="small-caps"/>
          <val eq="AllCaps" target-name="css:text-transform" target-value="uppercase"/>
          <val eq="CapToSmallCap" target-name="css:text-transform" target-value="uppercase"/><!-- ? -->
          <val eq="Normal" target-name="css:text-transform" target-value="none"/>
        	<val eq="Normal" target-name="css:font-variant" target-value="normal"/>
        </prop>
        <prop name="aid:ccolwidth" type="length" target-name="css:width"/>
        <prop name="idml2xml:width" type="length" target-name="css:width"/>
        <prop name="CharacterDirection" target-name="css:direction">
          <val eq="DefaultDirection" target-value="ltr"/>
          <val eq="LeftToRightDirection" target-value="ltr"/>
          <val eq="RightToLeftDirection" target-value="rtl"/>
        </prop>
        <prop name="FillColor" type="color" target-name="css:background-color">
          <context match="Para|Char|genSpan" target-name="css:color"/>
        </prop>
        <prop name="StartRowFillColor" type="color" target-name="idml2xml:StartRowFillColor"/>
        <prop name="StartRowFillTint" type="percentage" target-name="idml2xml:StartRowFillTint"/>
        <prop name="EndRowFillColor" type="color" target-name="idml2xml:EndRowFillColor"/>
        <prop name="EndRowFillTint" type="percentage" target-name="idml2xml:EndRowFillTint"/>
        <prop name="StopColor" type="color" target-name="css:background-color"/>
        <prop name="FillTint" type="percentage" target-name="fill-tint"/>
        <prop name="FirstLineIndent" type="length" target-name="css:text-indent" />
        <prop name="FontStyle">
          <val match="Cond(ensed)?" target-name="css:font-stretch" target-value="condensed" />
          <val match="(^|\W)Bold" target-name="css:font-weight" target-value="bold" />
          <val eq="Bold" target-name="css:font-style" target-value="normal" />
          <val eq="Bold" target-name="css:font-weight" target-value="bold" />
          <val eq="SemiLight" target-name="css:font-style" target-value="normal" />
          <val eq="SemiLight" target-name="css:font-weight" target-value="300" />
          <val match="Light" target-name="css:font-weight" target-value="300" />
          <val eq="Light" target-name="css:font-style" target-value="normal" />
          <val eq="Light" target-name="css:font-weight" target-value="300" />
          <val match="^\d+ Light$" target-name="css:font-style" target-value="normal" />
          <val match="Semi[bB]old" target-name="css:font-weight" target-value="600" />
          <val match="(Black|Heavy)" target-name="css:font-weight" target-value="900" />
          <val eq="Black" target-name="css:font-style" target-value="normal" />
          <val eq="Black" target-name="css:font-weight" target-value="900" />
          <val eq="Heavy" target-name="css:font-style" target-value="normal" />
          <val eq="Heavy" target-name="css:font-weight" target-value="900" />
          <val match="(Italic|Kursiv)" target-name="css:font-style" target-value="italic" />
          <val eq="Italic" target-name="css:font-style" target-value="italic" />
          <val eq="Italic" target-name="css:font-weight" target-value="normal" />
          <val eq="Kursiv" target-name="css:font-style" target-value="italic" />
          <val eq="Kursiv" target-name="css:font-weight" target-value="normal" />
          <val match="Oblique" target-name="css:font-style" target-value="oblique" />
          <val eq="Oblique" target-name="css:font-style" target-value="oblique" />
          <val eq="Oblique" target-name="css:font-weight" target-value="normal" />
          <val match="Medium" target-name="css:font-weight" target-value="normal" />
          <val eq="Medium" target-name="css:font-style" target-value="normal" />
          <val eq="Medium" target-name="css:font-weight" target-value="normal" />
          <!-- 7/2024 introduced not-match to avoid css:font-weight="bold normal" from FontStyle="Bold Plain"-->
          <val match="(Regular|Plain)" not-match="[Bb]old" target-name="css:font-weight" target-value="normal" />
          <val match="Regular" target-name="css:font-style" target-value="normal" />
          <val match="^((\d+ )?(Condensed ))?Roman( Condensed)?$" target-name="css:font-weight" target-value="normal" />
          <val match="Roman" target-name="css:font-style" target-value="normal" />
        	<!-- One of our customers (Hogrefe) uses a font (Lyon) with cleverly named font-style "Regular Italic" -->
        	<val match="Regular Italic" target-name="css:font-weight" target-value="normal" />
          <val match="Regular Italic" target-name="css:font-style" target-value="italic" />
          <!-- Aufbau uses font with style "Light Classic Roman" -->
          <val eq="Light Classic Roman" target-name="css:font-style" target-value="normal" />
          <val eq="Light Classic Roman" target-name="css:font-weight" target-value="300" />
        </prop>
        <prop name="Hidden" target-name="css:display">
          <val eq="true" target-value="none"/>
          <val eq="false"/>
        </prop>
        <prop name="HorizontalScale" type="percentage" target-name="css:_transform_scaleX"/>
        <prop name="Hyphenation" target-name="css:hyphens">
          <val eq="true" target-value="auto"/>
          <val eq="false" target-value="manual"/>
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
        <prop name="NumberingContinue" target-name="hub:numbering-continue" type="linear"/>
        <prop name="NumberingExpression" target-name="numbering-expression" type="linear"/>
        <prop name="NumberingFormat" target-name="numbering-format" type="linear"/>
        <prop name="NumberingLevel" target-name="numbering-level" type="linear"/>
        <prop name="NumberingStartAt" target-name="numbering-starts-at" type="linear"/>
        <prop name="ParagraphBreakType" >
          <val match="NextPage|NextPage" target-name="css:page-break-after" target-value="always"/>
          <val eq="NextOddPage" target-name="css:page-break-after" target-value="right"/>
          <val eq="NextEvenPage" target-name="css:page-break-after" target-value="left"/>
          <val match="NextColumn" target-name="css:break-after" target-value="column"/>
          <val match="NextFrame" target-name="css:break-after" target-value="always"/>
        </prop>
        <prop name="ParagraphDirection" target-name="css:direction">
          <!-- string | string "LeftToRightDirection" | string "RightToLeftDirection" -->
          <val eq="RightToLeftDirection" target-value="rtl"/>
        </prop>
        <prop name="PointSize" type="length" target-name="css:font-size" />
        <prop name="Position" type="position" target-name="css:vertical-align" />
        <prop name="RightIndent" type="length" target-name="css:margin-right" />
        <prop name="RightInset" type="length" target-name="css:padding-right" />
        <prop name="ShadowColor" type="color" target-name="shadow-color" />
        <prop name="SpaceAfter" type="length" target-name="css:margin-bottom" />
        <prop name="SameParaStyleSpacing" type="length" target-name="hub:same-para-style-spacing"/>
        <prop name="SpaceBefore" type="length" target-name="css:margin-top" />
        <prop name="StartParagraph">
          <val eq="NextPage" target-name="css:page-break-before" target-value="always"/>
          <val eq="NextOddPage" target-name="css:page-break-before" target-value="right"/>
          <val eq="NextEvenPage" target-name="css:page-break-before" target-value="left"/>
          <val eq="Anywhere" target-name="css:page-break-before" target-value="auto"/>
          <val match="NextColumn" target-name="css:break-before" target-value="column"/>
          <val match="NextFrame" target-name="css:break-before" target-value="always"/>
        </prop>
        <prop name="StrikeThru" target-name="css:text-decoration-line">
          <val eq="true" target-value="line-through"/>
          <val eq="false" target-value="line-through:none"/>
        </prop>
        <prop name="TabList" type="tablist"/>
        <prop name="TextBottomInset" type="length" target-name="css:padding-bottom" />
        <prop name="TextLeftInset" type="length" target-name="css:padding-left" />
        <prop name="TextRightInset" type="length" target-name="css:padding-right" />
        <prop name="TextTopInset" type="length" target-name="css:padding-top" />
        <prop name="TintValue" type="percentage" target-name="fill-value"/>
        <prop name="TopInset" type="length" target-name="css:padding-top" />
        <prop name="Underline" target-name="css:text-decoration-line">
          <val eq="true" target-value="underline"/>
          <val eq="false"  target-value="underline:none"/>
        </prop>
        <prop name="UnderlineColor" type="color" target-name="css:text-decoration-color"/>
        <prop name="UnderlineOffset" type="length" target-name="css:text-decoration-offset"/>
        <prop name="UnderlineTint" implement="implicitly with UnderlineColor" />
        <prop name="UnderlineType" implement="use text-decoration-style must look at Stroke/..." />
        <prop name="UnderlineWeight" type="length" target-name="css:text-decoration-width" /><!-- proposed here:
          http://lists.w3.org/Archives/Public/www-style/2012Jul/0445.html but not yet in
          http://dev.w3.org/csswg/css-text-decor-3/ as at 2013-02-08 -->
        <prop name="VerticalJustification">
          <val match="TopAlign" target-name="css:vertical-align" target-value="top" />
          <val match="CenterAlign" target-name="css:vertical-align" target-value="middle" />
          <val match="BottomAlign" target-name="css:vertical-align" target-value="bottom" />
        </prop>
        <prop name="VerticalScale" type="percentage" target-name="css:_transform_scaleY" />
        <!-- For Condition elements: -->
        <prop name="Visible" target-name="css:display" hubversion="1.1">
          <val eq="false" target-value="none"/>
          <!-- <val eq="true"/> --><!-- Visible="true": unnecessary css:display attribute -->
        </prop>
        <prop name="xlink:href" type="passthru"/>

        <prop name="NumberingApplyRestartPolicy" target-name="hub:restart" type="linear"/>
        <prop name="idml2xml:NumberingRestartPoliciesLowerLevel" target-name="hub:restart-at-lower-level" type="linear"/>
        <prop name="idml2xml:NumberingRestartPoliciesUpperLevel" target-name="hub:restart-at-upper-level" type="linear"/>
        <prop name="BulletsAlignment" implement="maybe later" />
        <prop name="NumberingAlignment" implement="maybe later" />
        <prop name="BulletsTextAfter" implement="maybe later" />
        <prop name="DigitsType" implement="maybe later" />


        <prop name="AutoLeading" implement="maybe later" />
        <prop name="BaselineShift" implement="maybe later" />
        <prop name="Composer" implement="maybe later" />
        <prop name="DropCapCharacters" type="linear" target-name="hub:drop-cap-chars"/>
        <prop name="DropCapLines" type="linear" target-name="css:initial-letter" />
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
        <prop name="StrokeColor" type="color" target-name="css:border-color"/>
        <prop name="StrokeWeight" type="length" target-name="css:border-width"/>
        <prop name="StrikeThroughType" target-name="css:text-decoration-style">
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="double"/>
          <val match="ThickThinThick" target-value="double"/>
          <val match="ThinThick" target-value="double"/>
          <val match="ThinThickThin" target-value="double"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="wavy"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="UnderlineType" target-name="css:text-decoration-style">
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="double"/>
          <val match="ThickThinThick" target-value="double"/>
          <val match="ThinThick" target-value="double"/>
          <val match="ThinThickThin" target-value="double"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="wavy"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="StrokeType" target-name="css:border-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="/ThinThickThin$" target-value="ridge"/>
          <val match="/ThickThick$" target-value="double"/>
          <val match="/ThickThin$" target-value="groove"/>
          <val match="/ThickThinThick$" target-value="groove"/>
          <val match="/ThinThick$" target-value="ridge"/>
          <val match="/ThinThin$" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="TopEdgeStrokeType" target-name="css:border-top-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="TopBorderStrokeType" target-name="css:border-top-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>        
        <prop name="LeftEdgeStrokeType" target-name="css:border-left-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="LeftBorderStrokeType" target-name="css:border-left-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>        
        <prop name="BottomEdgeStrokeType" target-name="css:border-bottom-style">
           <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="BottomBorderStrokeType" target-name="css:border-bottom-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>        
        <prop name="RightEdgeStrokeType" target-name="css:border-right-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val eq="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="RightBorderStrokeType" target-name="css:border-right-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val match="StrokeStyle/$ID/Dashed" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <prop name="LeftBorderStrokeColor" type="color" target-name="css:border-left-color"/>
        <prop name="BottomBorderStrokeColor" type="color" target-name="css:border-bottom-color"/>
        <prop name="RightBorderStrokeColor" type="color" target-name="css:border-right-color"/>
        <prop name="TopBorderStrokeColor" type="color" target-name="css:border-top-color"/>
        <prop name="LeftEdgeStrokeColor" type="color" target-name="css:border-left-color"/>
        <prop name="BottomEdgeStrokeColor" type="color" target-name="css:border-bottom-color"/>
        <prop name="RightEdgeStrokeColor" type="color" target-name="css:border-right-color"/>
        <prop name="TopEdgeStrokeColor" type="color" target-name="css:border-top-color"/>
        <prop name="TopBorderStrokeWeight" type="length" target-name="css:border-top-width"/>
        <prop name="LeftBorderStrokeWeight" type="length" target-name="css:border-left-width"/>
        <prop name="BottomBorderStrokeWeight" type="length" target-name="css:border-bottom-width"/>
        <prop name="RightBorderStrokeWeight" type="length" target-name="css:border-right-width"/>
        <prop name="LeftEdgeStrokeTint" type="percentage" target-name="border-left-tint"/>
        <prop name="BottomEdgeStrokeTint" type="percentage" target-name="border-bottom-tint"/>
        <prop name="RightEdgeStrokeTint" type="percentage" target-name="border-right-tint"/>
        <prop name="TopEdgeStrokeTint" type="percentage" target-name="border-top-tint"/>
        <prop name="TopEdgeStrokeWeight" type="length" target-name="css:border-top-width"/>
        <prop name="LeftEdgeStrokeWeight" type="length" target-name="css:border-left-width"/>
        <prop name="BottomEdgeStrokeWeight" type="length" target-name="css:border-bottom-width"/>
        <prop name="RightEdgeStrokeWeight" type="length" target-name="css:border-right-width"/>
        <prop name="TopLeftCornerRadius" type="length" target-name="css:border-top-left-radius"/>
        <prop name="TopRightCornerRadius" type="length" target-name="css:border-top-right-radius"/>
        <prop name="BottomLeftCornerRadius" type="length" target-name="css:border-bottom-left-radius"/>
        <prop name="BottomRightCornerRadius" type="length" target-name="css:border-bottom-right-radius"/>
        <prop name="Tracking" type="one-thousandth-em-length" target-name="css:letter-spacing"/>
        <!-- para borders -->
        <prop name="ParagraphBorderOn" target-name="hub:para-border">
          <val match="true" target-value="true"/>
          <val match="false" target-value="false"/>
        </prop>
        <prop name="ParagraphBorderTopOffset" type="length" target-name="hub:para-border-padding-top"/>
        <prop name="ParagraphBorderRightOffset" type="length" target-name="hub:para-border-padding-right"/>
        <prop name="ParagraphBorderBottomOffset" type="length" target-name="hub:para-border-padding-bottom"/>
        <prop name="ParagraphBorderLeftOffset" type="length" target-name="hub:para-border-padding-left"/>
        <prop name="ParagraphBorderTopLineWeight" type="length" target-name="hub:para-border-top-width"/>
        <prop name="ParagraphBorderRightLineWeight" type="length" target-name="hub:para-border-right-width"/>
        <prop name="ParagraphBorderBottomLineWeight" type="length" target-name="hub:para-border-bottom-width"/>
        <prop name="ParagraphBorderLeftLineWeight" type="length" target-name="hub:para-border-left-width"/>
        <prop name="ParagraphBorderColor" type="color" target-name="hub:para-border-color"/>
        <prop name="ParagraphBorderGapColor" type="color" target-name="hub:para-border-gap-color"/>
        <prop name="ParagraphBorderTint" type="percentage" target-name="hub:para-border-tint"/>
        <prop name="ParagraphBorderGapTint" type="percentage" target-name="hub:para-border-gap-tint"/>
        <prop name="ParagraphBorderType" target-name="hub:para-border-style">
          <val eq="n" target-value="none"/>
          <val match="Solid" target-value="solid"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThickThin" target-value="groove"/>
          <val match="ThickThinThick" target-value="groove"/>
          <val match="ThinThick" target-value="ridge"/>
          <val match="ThinThickThin" target-value="ridge"/>
          <val match="ThinThin" target-value="double"/>
          <val match="Canned\sDashed\s3x2" target-value="dashed"/>
          <val match="Canned\sDashed\s4x4" target-value="dashed"/>
          <val match="Canned\sDotted" target-value="dotted"/>
          <val match="Japanese\sDots" target-value="dotted"/>
          <val match="Wavy" target-value="groove"/>
          <val match="Left\sSlant\sHash" target-value="dashed"/>
          <val match="Right\sSlant\sHash" target-value="dashed"/>
          <val match="Straight\sHash" target-value="dashed"/>
          <val match="White\sDiamond" target-value="dashed"/>
        </prop>
        <!-- para shading -->
        <prop name="ParagraphShadingOn" target-name="hub:para-background">
          <val match="true" target-value="true"/>
          <val match="false" target-value="false"/>
        </prop>
        <prop name="ParagraphShadingColor" type="color" target-name="hub:para-background-color"/>
        <prop name="ParagraphShadingTint" type="percentage" target-name="hub:para-background-tint"/>
        <prop name="ParagraphShadingTopOffset" type="length" target-name="hub:para-background-padding-top"/>
        <prop name="ParagraphShadingRightOffset" type="length" target-name="hub:para-background-padding-right"/>
        <prop name="ParagraphShadingBottomOffset" type="length" target-name="hub:para-background-padding-bottom"/>
        <prop name="ParagraphShadingLeftOffset" type="length" target-name="hub:para-background-padding-left"/>

        <prop name="RotationAngle"  >
          <val match="(270|90)" target-name="css:text-orientation" target-value="sideways" />
          <val match="(270|90)" target-name="css:writing-mode" target-value="vertical-lr" />
           <!-- Text Rotation in Cells. rotate doesn't enlarge cells automatically whereas text-orientation does. -->
          <!--<val eq="180" target-name="css:transform" target-value="rotate(180deg)" />-->
        </prop>
        
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
        <prop name="KeepAllLinesTogether" implement="maybe later" />
        <prop name="KeepWithNext" target-name="css:page-break-after">
          <val match="[1-9].*" target-value="avoid"/>
        </prop>
        <prop name="KeepFirstLines" implement="maybe later" />
        <prop name="KeepLastLines" implement="maybe later" />
        <prop name="CharacterAlignment" implement="maybe later" />
        <prop name="KeepLinesTogether" implement="maybe later" />
        <prop name="StrokeTint" implement="maybe later"/>
        <prop name="OverprintStroke" implement="maybe later" />
        <prop name="OverprintFill" implement="maybe later" />
        <prop name="GradientStrokeAngle" implement="maybe later" />
        <prop name="GradientFillAngle" implement="maybe later" />
        <prop name="GradientStrokeLength" implement="maybe later" />
        <prop name="GradientFillLength" implement="maybe later" />
        <prop name="GradientStrokeStart" implement="maybe later" />
        <prop name="GradientFillStart" implement="maybe later" />
        <prop name="Skew" implement="maybe later" />
        <prop name="RuleAboveLineWeight" type="length" target-name="css:border-top-width"/>
        <prop name="RuleAboveTint" type="percentage" target-name="border-top-tint" />
        <prop name="RuleAboveOffset" type="length" target-name="css:padding-top"/>
        <prop name="RuleAboveLeftIndent" implement="maybe later" />
        <prop name="RuleAboveRightIndent" implement="maybe later" />
        <prop name="RuleAboveWidth" implement="maybe later" />
        <prop name="RuleBelowLineWeight" type="length" target-name="css:border-bottom-width"/>
        <prop name="RuleBelowTint" type="percentage" target-name="border-bottom-tint" />
        <prop name="RuleBelowOffset" type="length" target-name="css:padding-bottom"/>
        <prop name="RuleBelowLeftIndent" implement="maybe later" />
        <prop name="RuleBelowRightIndent" implement="maybe later" />
        <prop name="RuleBelowWidth" implement="maybe later" />
        <prop name="RuleAboveOverprint" implement="maybe later" />
        <prop name="RuleBelowOverprint" implement="maybe later" />
        <prop name="RuleAbove" target-name="css:border-top">
          <val eq="false" target-value="none"/>
          <val eq="true" target-value="border-top"/>
        </prop>
        <prop name="RuleBelow" target-name="css:border-bottom">
          <val eq="false" target-value="none"/>
          <val eq="true" target-value="border-bottom"/>
        </prop>
        <prop name="RuleBelow" implement="maybe later" />
        <prop name="LastLineIndent" implement="maybe later" />
        <prop name="HyphenateLastWord" implement="maybe later" />
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
        <prop name="UnderlineOverprint" implement="maybe later" />
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

        <prop name="SpanSplitColumnCount" implement="maybe later" />
        <prop name="KeepWithPrevious" implement="maybe later" />
        <prop name="SpanColumnMinSpaceBefore" implement="maybe later" />
        <prop name="SpanColumnMinSpaceAfter" implement="maybe later" />
        <prop name="SpanColumnType" implement="maybe later" />
        <prop name="SplitColumnInsideGutter" implement="maybe later" />
        <prop name="SplitColumnOutsideGutter" implement="maybe later" />
        
        <prop name="Kashidas" implement="maybe later" />
        <prop name="DiacriticPosition" implement="maybe later" />
        <prop name="ParagraphDirection" implement="maybe later" />
        <prop name="ParagraphJustification" implement="maybe later" />
        <prop name="ParagraphKashidaWidth" implement="maybe later" />
        
        <prop name="XOffsetDiacritic" implement="maybe later" />
        <prop name="YOffsetDiacritic" implement="maybe later" />
        <prop name="OTFOverlapSwash" implement="maybe later" />
        <prop name="OTFStylisticAlternate" implement="maybe later" />
        <prop name="OTFJustificationAlternate" implement="maybe later" />
        <prop name="OTFStretchedAlternate" implement="maybe later" />
        <prop name="KeyboardDirection" implement="maybe later" />
        <prop name="KeyboardShortcut" implement="maybe later" />
        <prop name="Leading" target-name="css:line-height">
          <val eq="Auto" target-value="normal" target-name="css:line-height"/>
          <val match="^\d+(\.\d+)?$" type="length" target-name="css:line-height"/>
        </prop>
        <prop name="RuleAboveColor" type="color" target-name="css:border-top-color"/>
        <prop name="RuleBelowColor" type="color" target-name="css:border-bottom-color"/>
        <prop name="RuleAboveType" target-name="css:border-top-style">
          <val match="Dash" target-value="dashed"/>
          <val match="Dotted" target-value="dotted"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThinThin" target-value="double"/>
          <val match="ThinThick" target-value="double"/>
          <val match="ThickThin" target-name="css:text-decoration-line" target-value="double"/>
          <val match="Solid" target-value="solid"/>
          <val match="Wavy" target-value="groove"/>
        </prop>
        <prop name="RuleBelowType" target-name="css:border-bottom-style">
          <val match="Dash" target-value="dashed"/>
          <val match="Dotted" target-value="dotted"/>
          <val match="ThickThick" target-value="double"/>
          <val match="ThinThin" target-value="double"/>
          <val match="ThinThick" target-value="double"/>
          <val match="ThickThin" target-value="double"/>
          <val match="Solid" target-value="solid"/>
          <val match="Wavy" target-value="groove"/>
        </prop>
        <prop name="BalanceRaggedLines" implement="maybe later" />
        <prop name="RuleAboveGapColor" implement="maybe later" />
        <prop name="RuleBelowGapColor" implement="maybe later" />
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
        <prop name="NumberingRestartPolicies" implement="maybe later" />
        <prop name="BulletsCharacterStyle" implement="maybe later" />
        <prop name="NumberingCharacterStyle" target-name="numbering-inline-stylename" type="linear"/>

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
