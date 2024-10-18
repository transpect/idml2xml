<?xml version="1.0" encoding="UTF-8" ?>
<!--

  INFORMATION
  Main file of the 'IDML to XML' converter.

-->
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:xhtml = "http://www.w3.org/1999/xhtml"
    xmlns:dbk="http://docbook.org/ns/docbook"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://transpect.io/idml2xml"
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
  <xsl:import href="modes/NestedStyles.xsl"/>
  <xsl:import href="modes/JoinSpans.xsl"/>
  <!-- GenerateHubformat: convert to le-tex Hub format -->
  <xsl:import href="modes/GenerateHubformat.xsl"/>
  <!-- Statistics: output summaries of the idml document to a separate html-file -->
  <xsl:import href="modes/Statistics.xsl"/>
  <!-- IndexTerms: unsorted indexterms (with page numers, if available as pseudo links) -->
  <xsl:import href="modes/Index.xsl"/>
  <!-- Images: extract image properties (width, height, resizing and other) -->
  <xsl:import href="modes/Images.xsl"/>
  

  <!-- If you are running individual modes with Saxon, it might happen that the output contains only text nodes.
    We believe this to be a Saxon bug. Supply '!method=xml' as in this example:
    saxon  -s:s.xml -xsl:idml2xml/xsl/idml2xml.xsl -o:o.xml \
      -im:{http://transpect.io/idml2xml}XML-Hubformat-add-properties '!method=xml' \ 
      src-dir-uri=file:/C:/cygwin/home/…/…/s.idml.tmp/
  If you are processing debug output, make sure to invoke the whole process with
  debug-dir-uri=file:/…?indent=false
  -->
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
      encoding="UTF-8" 
      byte-order-mark="yes" 
      method="text" 
      name="text"/>
  <xsl:output 
      name="debug" 
      method="xml" 
      encoding="utf-8" 
      indent="yes" />

  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="Delimiter Content idml2xml:* dbk:*"/>

  <xsl:param name="src-dir-uri" as="xs:string"/>
  <xsl:param name="archive-dir-uri" as="xs:string" select="replace($src-dir-uri, '[^/]+/?$', '')"/>
  <xsl:param name="srcpaths" as="xs:string" select="'no'"/>
  <xsl:param name="all-styles" as="xs:string" select="'no'"/>
  <xsl:param name="discard-tagging" as="xs:string" select="'no'"/>
  <xsl:param name="process-embedded-images" as="xs:string" select="'yes'"/>
  <xsl:param name="preserve-original-image-refs" as="xs:string" select="'no'"/>
  <xsl:param name="fixed-layout" as="xs:string" select="'no'"/>
  <xsl:param name="numeric-font-weight-values" as="xs:string" select="'no'"/>
  <xsl:param name="item-not-on-workspace-pt-tolerance" as="xs:string" select="'1'"/>
  <xsl:param name="debug" select="'0'" as="xs:string"/>
  <xsl:param name="debugdir" select="'debug'" as="xs:string"/>

  <!-- Comma separated list of inline element names (e.g., 'span,html:span')
       which to split when they stretch across layout paragraphs: -->
  <xsl:param name="split" as="xs:string?"/>

  <!-- On hubformat output: specifiy other allowed element names here (otherwise element and content will be removed) 
       comma-separated list of element names -->
  <xsl:param name="hub-other-elementnames-whitelist" select="''" as="xs:string"/>

  <xsl:param name="output-items-not-on-workspace" select="'no'" as="xs:string"/>
  <!-- Text with the condition StoryID for attaching IDs to Stories. 
       Text with the condition StoryRef for anchoring these Stories. 
       (We’re not talking about anchoring TextFrames here because this
       mechanism actually works on Story Level) -->
  <xsl:param name="use-StoryID-conditional-text-for-anchoring" select="'yes'" as="xs:string"/>
  <xsl:param name="export-all-articles" as="xs:string" select="'no'">
    <!-- if set to 'yes' -> do not consider Article/@ArticleExportStatus-->
  </xsl:param>
  <xsl:param name="output-deleted-text" select="'no'" as="xs:string"/>

  <xsl:param name="hub-version" select="'1.2'" as="xs:string"/>
  

  <xsl:variable 
    name="idml2xml:basename" 
    select="replace($src-dir-uri, '^(.*/)([^.]+?)(\..+)?$', '$2')"
    as="xs:string" />
  
  <xsl:variable
    name="idml2xml:split-these-elements-if-they-stretch-across-paragraphs" 
    select="for $eltname in tokenize($split, ',')
            return concat('XMLTag/', replace($eltname, ':', '%3a'))" 
    as="xs:string*" />

</xsl:stylesheet>
