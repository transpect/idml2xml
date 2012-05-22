<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:xhtml = "http://www.w3.org/1999/xhtml"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
    exclude-result-prefixes = "xs idPkg idml2xml xhtml"
>

  <xsl:template match="* | @* | comment() | processing-instruction()" priority="-1"
    mode="idml2xml:AutoCorrect
          idml2xml:AutoCorrect-group-pseudoparas
          idml2xml:AutoCorrect-clean-up
          idml2xml:Document
          idml2xml:DocumentStoriesSorted
          idml2xml:DocumentResolveTextFrames
          idml2xml:SeparateParagraphs-pull-down-psrange
          idml2xml:SeparateParagraphs
          idml2xml:ConsolidateParagraphStyleRanges
          idml2xml:ConsolidateParagraphStyleRanges-elim-br
          idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br
          idml2xml:ConsolidateParagraphStyleRanges-remove-empty
          idml2xml:ConsolidateParagraphStyleRanges-remove-ranges
          idml2xml:GenerateTagging
          idml2xml:IndexTerms-Topics
          idml2xml:IndexTerms-SeeAlso
          idml2xml:Statistics
          idml2xml:ExtractTagging
          idml2xml:XML-Hubformat-add-properties
          idml2xml:XML-Hubformat-extract-frames
          idml2xml:XML-Hubformat-remap-para-and-span
          idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


</xsl:stylesheet>
