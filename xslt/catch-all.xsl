  <!DOCTYPE xsl:stylesheet [
    <!ENTITY  catchAllModes
        " 
          idml2xml:AutoCorrect
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
          idml2xml:XML-Hubformat-cleanup-paras-and-br
        "
    >
  ]>
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

  <!--== Catch-All: import in main stylesheet, add new catch-all modes in &catchAllModes; ==-->


  <xsl:template match="*" mode="&catchAllModes;" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- place attributes in right namespace -->
  <xsl:template match="@*" mode="&catchAllModes;" name="makeNsAttribute" priority="-1">
    <xsl:param name="Attribute" select="." as="attribute()"/>
    <xsl:param name="AttributeFullName" select="replace( name(), '%3a', ':' )" as="xs:string+"/>
    <xsl:variable name="AttrName" select="idml2xml:substr( 'a', $AttributeFullName, ':' )" as="xs:string+"/>
    <xsl:variable name="AttrSpace" select="idml2xml:substr( 'b', $AttributeFullName, ':' )" as="xs:string+"/>
    <xsl:choose>
      <xsl:when test="matches( $AttributeFullName, ':' )  and  ( $idml2xml:Namespaces/ns[ @short = $AttrSpace ]/@space != '' )">
      <!--<xsl:message select="'1', $Attribute, '2',$AttributeFullName, '3', $AttrName ,'4', $AttrSpace, '5',$idml2xml:Namespaces/ns[ @short = $AttrName ]"/>-->
        <xsl:attribute name="{ $AttributeFullName }" select="$Attribute" namespace="{ $idml2xml:Namespaces/ns[ @short = $AttrSpace ]/@space }" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="{ $AttrName }" select="$Attribute" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction()" mode="&catchAllModes;" priority="-1">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>
