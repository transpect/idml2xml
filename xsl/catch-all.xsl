<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:idml2xml  = "http://transpect.io/idml2xml"
    exclude-result-prefixes = "xs idml2xml"
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
          idml2xml:ExtractTagging
          idml2xml:GenerateTagging
          idml2xml:IndexTerms-Topics
          idml2xml:Images
          idml2xml:NestedStyles-create-separators
          idml2xml:NestedStyles-pull-up-separators
          idml2xml:NestedStyles-upward-project
          idml2xml:NestedStyles-apply
          idml2xml:JoinSpans
          idml2xml:JoinSpans-unwrap
          idml2xml:Statistics
          idml2xml:XML-Hubformat-add-properties
          idml2xml:XML-Hubformat-properties2atts-compound
          idml2xml:XML-Hubformat-extract-frames
          idml2xml:XML-Hubformat-remap-para-and-span
          idml2xml:XML-Hubformat-modify-table-styles
          idml2xml:XML-Hubformat-cleanup-paras-and-br
          idml2xml:XML-Hubformat-without-srcpath">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
