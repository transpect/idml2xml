<?xml version="1.0" encoding="UTF-8" ?>
<!--

  INFORMATION
  Main file of the 'IDML to XML' converter.

-->
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:xhtml = "http://www.w3.org/1999/xhtml"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
    exclude-result-prefixes="idPkg aid5 aid xs idml2xml xhtml"
>

  <!--== TEMPLATES / FUNCTIONS INCLUSION ==-->
  <xsl:import href="catch-all.xsl"/>
  <xsl:import href="common-functions.xsl"/>
  <!-- Document: all files in one document -->
  <xsl:import href="modes/Document.xsl"/>
  <xsl:import href="modes/ConsolidateParagraphStyleRanges.xsl"/>
  <xsl:import href="modes/SeparateParagraphs.xsl"/>
  <!-- GenerateTagging: mode to add missing piggyback XML markup in IDML -->
  <xsl:import href="modes/GenerateTagging.xsl"/>
  <!-- ExtractTagging: mode to transform indesign tagging into xml structure -->
  <xsl:import href="modes/ExtractTagging.xsl"/>
  <!-- AutoCorrect: mode to correct aid:pstyle and aid:cstyle according to applied styles -->
  <xsl:import href="modes/AutoCorrect.xsl"/>
  <!-- GenerateHubformat: convert to le-tex Hub format -->
  <xsl:import href="modes/GenerateHubformat.xsl"/>
  <!-- Statistics: output summaries of the idml document to a separate html-file -->
  <xsl:import href="modes/Statistics.xsl"/>
  <!-- IndexTerms: unsorted indexterms (with page numers, if available as pseudo links) -->
  <xsl:import href="modes/Index.xsl"/>

  <!--== XSL OUTPUT ==-->
  <!-- removed saxon:suppress-indentation (and indent="yes") in order to make this vendor-neutral: -->
  <xsl:output 
      doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
      doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" 
      encoding="UTF-8"
      omit-xml-declaration="yes" byte-order-mark="yes"
      method="xhtml" 
      exclude-result-prefixes="#all" 
      name="xhtml"/>
  <xsl:output 
      indent="no" 
      encoding="UTF-8"
      omit-xml-declaration="no" 
      byte-order-mark="yes"
    exclude-result-prefixes="idPkg" method="xml" name="tagged"/>
  <xsl:output 
      indent="no" 
      encoding="UTF-8" 
      byte-order-mark="yes" 
      omit-xml-declaration="yes" 
      method="xml" 
      name="xml"/>
  <xsl:output 
      name="debug" 
      method="xml" 
      encoding="utf-8" 
      indent="yes" />

  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="Content"/>


  <!--== PARAMS ==-->
  <xsl:param name="src-dir-uri" as="xs:string"/>
  <xsl:param name="debug" select="'0'" as="xs:string"/>
  <xsl:param name="debugdir" select="'debug'" as="xs:string"/>
  <xsl:param name="srcpaths" as="xs:string"/>

  <!-- Comma separated list of inline element names (e.g., 'span,html:span')
       which to split when they stretch across layout paragraphs: -->
  <xsl:param name="split" as="xs:string?"/>

  <!-- On hubformat output: specifiy other allowed element names here (otherwise element and content will be removed) 
       comma-separated list of element names -->
  <xsl:param name="hub-other-elementnames-whitelist" select="''" as="xs:string"/>

  <!--== VARIABLES ==-->

  <xsl:variable name="designmap-doc" select="document(concat($src-dir-uri, '/', 'designmap.xml'))" as="document-node(element(Document))" />
  <xsl:variable
    name="idml2xml:idml-content-element-names" 
    select="('TextVariableInstance', 'Content', 'Rectangle', 'PageReference', 'idml2xml:genAnchor', 'TextFrame')" 
    as="xs:string+" />
  <xsl:variable 
    name="idml2xml:idml-scope-terminal-names"
    select="($idml2xml:idml-content-element-names, 'Br', 'idml2xml:genFrame', 'Footnote', 'Table', 'Story', 'XmlStory', 'Cell', 'CharacterStyleRange')" 
    as="xs:string+" />
  <xsl:variable
    name="idml2xml:split-these-elements-if-they-stretch-across-paragraphs" 
    select="for $eltname in tokenize($split, ',')
            return concat('XMLTag/', replace($eltname, ':', '%3a'))" 
    as="xs:string*" />
  <xsl:variable 
    name="idml2xml:basename" 
    select="replace($src-dir-uri, '^(.*/)([^.]+?)(\..+)?$', '$2')"
    as="xs:string" />
  <xsl:variable
    name="designmap-root"
    select="$designmap-doc"
    as="document-node(element(Document))" />

  <!-- The remainder of this file is only for an XSLT-only transformation pipeline.
       It's irrelevant to XProc processing (the variables won't be computed because
       they will be referenced nowhere -->

  <!--== PROCESSING PIPELINE ==-->

  <!-- generate an all in one xml-file -->
  <xsl:variable name="idml2xml:Document" as="document-node(element(Document))">
    <!-- need to read a named file instead of / of the default input because of XProc compatibility
         (otherwise the idml2xml:Document variable will be filled with the input of the current step) -->
    <xsl:apply-templates select="$designmap-doc" mode="idml2xml:Document"/>
  </xsl:variable>
  <!-- write an HTML summary -->
  <xsl:variable name="idml2xml:Statistics">
    <xsl:apply-templates select="$idml2xml:Document" mode="idml2xml:Statistics"/>
  </xsl:variable>
  <!-- order stories in right sequence -->
  <xsl:variable name="idml2xml:DocumentStoriesSorted">
    <xsl:apply-templates select="$idml2xml:Document" mode="idml2xml:DocumentStoriesSorted"/>
  </xsl:variable>
  <!-- In order to generate tagging for previously untagged content,
       it's important to immediately surround every paragraph with
       the ParagraphStyleRange that is in force there (SeparateParagraphs).
       -->
  <xsl:variable name="idml2xml:SeparateParagraphs-pull-down-psrange">
    <xsl:apply-templates select="$idml2xml:DocumentStoriesSorted" mode="idml2xml:SeparateParagraphs-pull-down-psrange"/>
  </xsl:variable>
  <xsl:variable name="idml2xml:SeparateParagraphs">
    <xsl:apply-templates select="$idml2xml:SeparateParagraphs-pull-down-psrange" mode="idml2xml:SeparateParagraphs"/>
  </xsl:variable>
  <!-- Pull up Br to the topmost position possible; eliminate empty ParagraphStyleRanges; 
       group the paragraphs
       (if there are disparate ParagraphStyleRanges with the same AppliedParagraphStyle, wrap them in a new ParagraphStyleRange) -->
  <xsl:variable name="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br">
    <xsl:apply-templates select="$idml2xml:SeparateParagraphs" mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br"/>
  </xsl:variable>
  <xsl:variable name="idml2xml:ConsolidateParagraphStyleRanges-remove-empty">
    <xsl:apply-templates select="$idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br" mode="idml2xml:ConsolidateParagraphStyleRanges-remove-empty"/>
  </xsl:variable>
  <xsl:variable name="idml2xml:ConsolidateParagraphStyleRanges">
    <xsl:apply-templates select="$idml2xml:ConsolidateParagraphStyleRanges-remove-empty" mode="idml2xml:ConsolidateParagraphStyleRanges"/>
  </xsl:variable>
  <!-- Generate tagging for previously untagged content: -->
  <xsl:variable name="idml2xml:GenerateTagging">
    <xsl:apply-templates select="$idml2xml:ConsolidateParagraphStyleRanges" mode="idml2xml:GenerateTagging"/>
  </xsl:variable>
  <!-- Make the XML structure explicit that has been carried along with the text so far: -->
  <xsl:variable name="idml2xml:ExtractTagging">
    <xsl:apply-templates select="$idml2xml:GenerateTagging" mode="idml2xml:ExtractTagging"/>
  </xsl:variable>
  <!-- autocorrect according to applied styles -->
  <xsl:variable name="idml2xml:AutoCorrect">
    <xsl:apply-templates select="$idml2xml:ExtractTagging" mode="idml2xml:AutoCorrect"/>
  </xsl:variable>
  <xsl:variable name="idml2xml:AutoCorrect-clean-up">
    <xsl:apply-templates select="$idml2xml:AutoCorrect" mode="idml2xml:AutoCorrect-clean-up"/>
  </xsl:variable>

  <!--== HUB variables ==-->
  <!-- add properties to block and inline tags -->
  <xsl:variable name="idml2xml:XML-Hubformat-add-properties">
    <xsl:apply-templates select="$idml2xml:AutoCorrect-clean-up" mode="idml2xml:XML-Hubformat-add-properties"/>
  </xsl:variable>
  <!-- make proper attributes out of intermediate ones -->
  <xsl:variable name="idml2xml:XML-Hubformat-properties2atts">
    <xsl:apply-templates select="$idml2xml:XML-Hubformat-add-properties" mode="idml2xml:XML-Hubformat-properties2atts"/>
  </xsl:variable>
  <!-- extract anchored frames from paras -->
  <xsl:variable name="idml2xml:XML-Hubformat-extract-frames">
    <xsl:apply-templates select="$idml2xml:XML-Hubformat-properties2atts" mode="idml2xml:XML-Hubformat-extract-frames"/>
  </xsl:variable>
  <!-- convert genSpan and genPara to Hubformat -->
  <xsl:variable name="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates select="$idml2xml:XML-Hubformat-extract-frames" mode="idml2xml:XML-Hubformat-remap-para-and-span"/>
  </xsl:variable>
  <!-- cleanup remapping -->
  <xsl:variable name="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:apply-templates select="$idml2xml:XML-Hubformat-remap-para-and-span" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  </xsl:variable>

  <!--== Index Terms ==-->
  <xsl:variable name="idml2xml:IndexTerms-extract" as="element(idml2xml:indexterms)">
    <idml2xml:indexterms>
      <xsl:apply-templates select="$idml2xml:DocumentStoriesSorted" mode="idml2xml:IndexTerms-extract"/>
      <!-- Index cross-refs (see, see also) aren't typically included in the stories, 
           therefore we have to collect them from the designmap: -->
      <xsl:apply-templates select="$designmap-root//Topic[CrossReference]" mode="idml2xml:IndexTerms-extract"/>
    </idml2xml:indexterms>
  </xsl:variable>

  <xsl:variable name="idml2xml:IndexTerms">
    <xsl:apply-templates select="$idml2xml:IndexTerms-extract" mode="idml2xml:IndexTerms"/>
  </xsl:variable>

  <!--== MAIN TEMPLATE ==-->
  <xsl:template name="tagged">
    <xsl:call-template name="debug-common" />
    <xsl:call-template name="debug-tagged" />
    <idml2xml:document processing="Document DocumentStoriesSorted SeparateParagraphs GenerateTagging AutoCorrect">
      <xsl:sequence select="$idml2xml:AutoCorrect-clean-up"/>
    </idml2xml:document>
  </xsl:template>

  <xsl:template name="hub">
    <xsl:call-template name="debug-common" />
    <xsl:call-template name="debug-tagged" />
    <xsl:call-template name="debug-hub" />
    <xsl:sequence select="$idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  </xsl:template>

  <xsl:template name="indexterms">
    <xsl:sequence select="$idml2xml:IndexTerms"/>
    <xsl:if test="$debug = ('1','yes')">
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, $idml2xml:basename, '05.Document.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:Document"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, $idml2xml:basename, '20.DocumentStoriesSorted.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:DocumentStoriesSorted"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '81.IndexTerms-extract.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:IndexTerms-extract"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '83.IndexTerms.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:IndexTerms"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <xsl:template name="debug-common">
    <xsl:if test="$debug = ('1','yes')">
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '05.Document.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:Document"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', 'aa.Statistics.html')}" format="debug">
        <xsl:copy-of select="$idml2xml:Statistics"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '20.DocumentStoriesSorted.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:DocumentStoriesSorted"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '22.SeparateParagraphs-pull-down-psrange.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:SeparateParagraphs-pull-down-psrange"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '24.SeparateParagraphs.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:SeparateParagraphs"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '26.ConsolidateParagraphStyleRanges-pull-up-Br.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '27.ConsolidateParagraphStyleRanges-remove-empty.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:ConsolidateParagraphStyleRanges-remove-empty"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '28.ConsolidateParagraphStyleRanges.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:ConsolidateParagraphStyleRanges"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '29.GenerateTagging.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:GenerateTagging"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '30.ExtractTagging.xml')}" format="debug">
        <xsl:copy-of select="$idml2xml:ExtractTagging"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>


  <xsl:template name="debug-tagged">
    <xsl:if test="$debug = ('1','yes')">
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '50.AutoCorrect.xml')}" format="debug">
	<xsl:sequence select="$idml2xml:AutoCorrect"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', '52.AutoCorrect-clean-up.xml')}" format="debug">
	<xsl:sequence select="$idml2xml:AutoCorrect-clean-up"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <xsl:template name="debug-hub">
    <xsl:if test="$debug = ('1','yes')">
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', 'HUB.07.XML-Hubformat-add-properties.xml')}" format="debug">
        <xsl:sequence select="$idml2xml:XML-Hubformat-add-properties"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', 'HUB.07a.XML-Hubformat-properties2atts.xml')}" format="debug">
        <xsl:sequence select="$idml2xml:XML-Hubformat-properties2atts"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', 'HUB.08.XML-Hubformat-extract-frames.xml')}" format="debug">
        <xsl:sequence select="$idml2xml:XML-Hubformat-extract-frames"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', 'HUB.10.XML-Hubformat-remap-para-and-span.xml')}" format="debug">
        <xsl:sequence select="$idml2xml:XML-Hubformat-remap-para-and-span"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', 'HUB.15.XML-Hubformat-cleanup-paras-and-br.xml')}" format="debug">
        <xsl:sequence select="$idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
      </xsl:result-document>
      <xsl:result-document href="{idml2xml:debug-uri($debugdir, 'idml2xml', 'HUB.20.XML-Hubformat-without-srcpath.xml')}" format="debug">
        <xsl:apply-templates select="$idml2xml:XML-Hubformat-cleanup-paras-and-br" mode="idml2xml:XML-Hubformat-without-srcpath"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>