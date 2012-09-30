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
  
  <xsl:function name="idml2xml:substr">
    <xsl:param name="direction" as="xs:string"/> <!-- before: b, after: a -->
    <xsl:param name="Token"/>
    <xsl:param name="Search" as="xs:string+"/>
    <xsl:variable name="SearchTerm" select="
    replace(  
      replace(  $Search,
                '\.',
                '[.]' ),
      '\$', 
      '\\\$' )
    " as="xs:string+"/>
    <xsl:choose>
      <xsl:when test="matches( $Token, $SearchTerm )">
        <xsl:choose>
          <xsl:when test="$direction = 'a'">
            <xsl:sequence select="substring-after( $Token, $Search )"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="substring-before( $Token, $Search )"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$Token"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="idml2xml:contains" as="xs:string?">
    <xsl:param name="tokens-string" as="xs:string"/>
    <xsl:param name="search-string" as="xs:string+" />
    <xsl:sequence select="$search-string[. = tokenize(if($tokens-string) then $tokens-string else '', '\s+')]"/>
  </xsl:function>

  <xsl:function name="idml2xml:debug-uri" as="xs:string">
    <xsl:param name="dir" as="xs:string"/>
    <xsl:param name="basename" as="xs:string"/>
    <xsl:param name="extension" as="xs:string"/>
    <xsl:sequence select="xs:string(resolve-uri(concat($dir, '/', $basename, '.', $extension)))"/>
  </xsl:function>

  <xsl:function name="idml2xml:AppliedParagraphStyle" as="xs:string">
    <xsl:param name="elt" as="element(*)" />
    <xsl:sequence select="$elt/ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle" />
  </xsl:function>

  <xsl:function name="idml2xml:StyleName" as="xs:string">
    <xsl:param name="stylename" as="xs:string"/>
    <xsl:sequence select="idml2xml:StyleNameEscape( idml2xml:RemoveTypeFromStyleName( $stylename) )"/>
  </xsl:function>

  <xsl:function name="idml2xml:StyleNameEscape" as="xs:string">
    <xsl:param name="stylename" as="xs:string"/>
    <xsl:sequence select="replace(
                            replace(
                              $stylename,
                             '[^\w%/.:]',
                              '_' 
                            ),
                            '%3a',
                            ':'
                          )"/>
  </xsl:function>

  <xsl:function name="idml2xml:RemoveTypeFromStyleName" as="xs:string">
    <xsl:param name="stylename" as="xs:string"/>
    <xsl:sequence select="replace( idml2xml:substr( 'a', $stylename, '$ID/' ), 
                          '(Paragraph|Character|Table|Cell|Object)Style/|\[|\]',
                          '' )"/>
  </xsl:function>

  <xsl:function name="idml2xml:escape-id" as="xs:string">
    <xsl:param name="input" as="xs:string"/>
    <xsl:sequence select="replace($input, '[/ ]', '_' )"/>
  </xsl:function>


  <xsl:function name="idml2xml:countIndexterms">
    <!-- type '1' = primary; type '2' = secondary; type '3' = tertiary; type '4' = quaternary -->
    <xsl:param name="type" as="xs:integer" />
    <xsl:param name="terms" />
      <xsl:variable name="occurencesIndexType">
        <xsl:for-each select="$terms">
          <xsl:if test="count( tokenize( current()/@ReferencedTopic, 'Topicn' ) ) gt ( $type )">
            <found/>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
    <xsl:value-of select="count( $occurencesIndexType//* )" />
  </xsl:function>


  <!-- Tests whether $elt is immediately contained in $ancestor-elt 
       (that is, in the same Story, in the same Cell, etc.). 
       Or phrased differently: whether $elt is in a paragraph
       where $ancestor-elt's ParagraphStyleRange is still in force.
       This function works with IDML input and with extracted XML,
       provided that @aid:table and @idml2xml:story are conserved 
       in the extracted XML.
       -->
  <xsl:function name="idml2xml:same-scope" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:param name="ancestor-elt" as="element(*)" />
    <xsl:sequence select="not($elt/ancestor::*[self::Cell 
                                               or @aid:table eq 'cell' 
                                               or self::Footnote
                                               or self::Story
                                               or self::XmlStory 
                                               or @idml2xml:story]
                                              [some $a in ancestor::* satisfies ($a is $ancestor-elt)])" />
  </xsl:function>

  <xsl:function name="idml2xml:br-first" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:sequence select="exists( 
                                  ($elt//*
                                    [name() = $idml2xml:idml-scope-terminal-names]
                                    [idml2xml:same-scope(., $elt)]
                                  )[1]
                                  /self::Br 
                                )" />
  </xsl:function>

  <xsl:function name="idml2xml:br-last" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:sequence select="exists( 
                                  ($elt//*
                                    [name() = $idml2xml:idml-scope-terminal-names]
                                    [idml2xml:same-scope(., $elt)]
                                  )[if (last() eq 1) then 2 else last()]
                                  /self::Br 
                                )" />
  </xsl:function>

  
  <!-- Tests whether $elt contains many paras -->
  <xsl:function name="idml2xml:has-many-paras" as="xs:boolean">
    <xsl:param name="elt" as="element(XMLElement)" />
    <xsl:variable name="children" select="$elt//*[idml2xml:same-scope(., $elt)]" as="element(*)+" />
    <xsl:sequence select="exists($elt//Br[exists(. intersect $children)]
                                         [exists(preceding::*[name() = $idml2xml:idml-content-element-names] intersect $children)]
                                         [exists(following::*[name() = $idml2xml:idml-content-element-names] intersect $children)]
                                )" />
  </xsl:function>


  <xsl:function name="idml2xml:same-level-ParagraphStyleRanges" as="element(ParagraphStyleRange)+">
    <xsl:param name="elt" as="element(ParagraphStyleRange)" />
    <xsl:sequence
      select="$elt/ancestor::*[self::Story or self::XmlStory or self::Cell][1]//
              ParagraphStyleRange[every $p in self::ParagraphStyleRange satisfies ($p//*[self::Content or self::Br][idml2xml:same-scope(., $p)])]
                [not(
                  some $a in (ancestor::Cell union ancestor::Story union ancestor::XmlStory) satisfies
                  (some $b in $a/ancestor::* satisfies ($b is $elt))
                 )]" />
  </xsl:function>


  <xsl:function name="idml2xml:elt-signature" as="xs:string*">
    <xsl:param name="elt" as="element(*)?" />
    <xsl:sequence select="if (exists($elt)) 
                          then string-join((name($elt), idml2xml:attr-hashes($elt)), '___')
                          else '' " />
  </xsl:function>

  <xsl:function name="idml2xml:attr-hashes" as="xs:string*">
    <xsl:param name="elt" as="node()*" />
    <xsl:perform-sort>
      <xsl:sort/>
      <xsl:sequence select="for $a in $elt/@* return idml2xml:attr-hash($a)" />
    </xsl:perform-sort>
  </xsl:function>

  <xsl:function name="idml2xml:attr-hash" as="xs:string">
    <xsl:param name="att" as="attribute(*)" />
    <xsl:sequence select="concat(name($att), '__=__', $att)" />
  </xsl:function>

  <xsl:function name="idml2xml:attname" as="xs:string">
    <xsl:param name="hash" as="xs:string" />
    <xsl:value-of select="replace($hash, '__=__.+$', '')" />
  </xsl:function>

  <xsl:function name="idml2xml:attval" as="xs:string">
    <xsl:param name="hash" as="xs:string" />
    <xsl:value-of select="replace($hash, '^.+__=__', '')" />
  </xsl:function>



  <!--  function replaces 
        - just replaces text -
        param 1: text to replace
        param 2: sequence of search- and replace-pattern 
         (e.g. ('\.', '-', '5', '3' ): "." -> "-" and 5 -> 3 -->
  <xsl:function name="idml2xml:replaces">
    <xsl:param name="replace-text" as="xs:string+"/>
    <xsl:param name="search-and-replacement" as="item()+"/>
    <xsl:variable 
        name="replaced" 
        select="replace( $replace-text, $search-and-replacement[1], $search-and-replacement[2] )"/>
    <xsl:sequence 
        select="if (count ($search-and-replacement) lt 3 )
                then $replaced
                else idml2xml:replaces( $replaced, $search-and-replacement[ position() gt 2 ])"/>
  </xsl:function>

</xsl:stylesheet>