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
            <xsl:value-of select="substring-after( $Token, $Search )"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="substring-before( $Token, $Search )"/>
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
    <xsl:value-of select="$search-string[. = tokenize(if($tokens-string) then $tokens-string else '', '\s+')]"/>
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

  <xsl:function name="idml2xml:StyleName">
    <xsl:param name="stylename" as="xs:string+"/>
    <xsl:value-of select="replace( idml2xml:RemoveTypeFromStyleName( $stylename), 
                          '\|| |[+]',
                          '' )"/>
  </xsl:function>
  
  <xsl:function name="idml2xml:RemoveTypeFromStyleName">
    <xsl:param name="stylename" as="xs:string+"/>
    <xsl:value-of select="replace( idml2xml:substr( 'a', $stylename, '$ID/' ), 
                          '(Paragraph|Character|Table|Cell|Object)Style/|\[|\]',
                          '' )"/>
  </xsl:function>

  <xsl:function name="idml2xml:attrname">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="replace(
                            replace($name, '^[^/]+/', ''),
                            '%3a',
                            ':'
                          )"/>
  </xsl:function>

  <xsl:function name="idml2xml:StyleProperty">
    <xsl:param name="property" as="attribute()"/>
    <xsl:choose>
      <xsl:when test="name( $property ) = 'PointSize'">
        <xsl:variable name="pt2em" select="xs:string( $property div 12 )" />
        <xsl:value-of select="(if( matches( $pt2em, '\.' ) ) 
                                then 
                                  ('  ', 'font-size: ', idml2xml:substr( 'b', $pt2em, '.' ), '.', substring( idml2xml:substr( 'a', $pt2em, '.' ), 1, 3 ) )
                                else 
                                  ( 'font-size: ', $pt2em )
                              ), 'em;'" separator=""/>
      </xsl:when>
      <xsl:when test="name( $property ) = 'Justification'">
        <xsl:value-of select="'text-align: ', $property, ';'" separator=""/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="' ', name( $property ), ': ', $property, ';'" separator=""/>
      </xsl:otherwise>
    </xsl:choose>
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
                                               or self::Story
                                               or self::idml2xml:genFrame
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

  <!-- 
function idml2xml:hubformat-add-property:
remap and output indesign attribute settings to hubformat

see: idml/_IDML_Schema_RelaxNGCompact or
http://cssdk.host.adobe.com/sdk/1.5/docs/WebHelp/references/csawlib/com/adobe/csawlib/CSEnumBase.html
  -->
  <xsl:function name="idml2xml:hubformat-add-property">
    <xsl:param name="style-node" as="attribute()"/>
    <xsl:choose>
      <xsl:when test="not (
                        local-name ($style-node) = 
                        ( 'Capitalization',
                          'CharacterDirection',
                          'FillColor',
                          'FirstLineIndent',
                          'FontStyle',
                          'Justification',
                          'LeftIndent',
                          'Name',
                          'PointSize',
                          'RightIndent',
                          'ShadowColor',
                          'StrikeThru',
                          'Underline')
                      ) " />
      <xsl:when test="local-name($style-node) eq 'StrikeThru' and $style-node eq 'false'" />
      <xsl:when test="local-name($style-node) eq 'CharacterDirection' and $style-node eq 'DefaultDirection'" />
      <xsl:when test="local-name($style-node) eq 'FontStyle' and $style-node eq 'Regular'" />
      <xsl:when test="local-name($style-node) eq 'FontStyle' and $style-node eq 'Bold Italic'">
        <xsl:attribute name="font-style" select="'italic'"/>
        <xsl:attribute name="font-weight" select="'bold'"/>
      </xsl:when>
      <xsl:when test="local-name($style-node) eq 'Justification' and $style-node eq 'LeftAlign'" />
      <xsl:otherwise>
        <xsl:attribute 
            name="{idml2xml:styleproperty-name-to-hubformat( $style-node )}" 
            select="idml2xml:styleproperty-value-to-hubformat( $style-node )" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="idml2xml:styleproperty-name-to-hubformat">
    <xsl:param name="property" as="attribute()"/>
    <xsl:variable name="property-name" select="name($property)" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$property-name = 'Capitalization' and $property eq 'SmallCaps'">
      	<xsl:sequence select="'font-variant'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'Capitalization'">
      	<xsl:sequence select="'text-transform'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'CharacterDirection'">
      	<xsl:sequence select="'text-direction'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'FillColor'">
      	<xsl:sequence select="'color'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'FirstLineIndent'">
      	<xsl:sequence select="'text-indent'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'FontStyle' and $property eq 'Italic'">
      	<xsl:sequence select="'font-style'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'FontStyle'">
      	<xsl:sequence select="'font-weight'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'Justification'">
      	<xsl:sequence select="'text-align'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'LeftIndent'">
      	<xsl:sequence select="'margin-left'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'Name'">
      	<xsl:sequence select="'role'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'PointSize'">
      	<xsl:sequence select="'font-size'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'RightIndent'">
      	<xsl:sequence select="'margin-right'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'ShadowColor'">
      	<xsl:sequence select="'text-shadow'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'StrikeThru'">
      	<xsl:sequence select="'text-decoration'"/>
      </xsl:when>
      <xsl:when test="$property-name = 'Underline'">
      	<xsl:sequence select="'text-decoration'"/>
      </xsl:when>
      <xsl:otherwise>
      	<xsl:sequence select="$property-name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--
      function idml2xml:styleproperty-value-to-hubformat
      see: idml/_IDML_Schema_RelaxNGCompact/datatype.rnc
  -->
  <xsl:function name="idml2xml:styleproperty-value-to-hubformat">
    <xsl:param name="property" as="attribute()"/>
    <xsl:variable name="propname" select="name ($property)" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$propname = 'Capitalization'">
        <!-- string "Normal" | string "SmallCaps" | string "AllCaps" | string "CapToSmallCap" -->
        <xsl:choose>
          <xsl:when test="$property eq 'SmallCaps'">smallcaps</xsl:when>
          <xsl:when test="$property eq 'AllCaps'">uppercase</xsl:when>
          <xsl:when test="$property eq 'CapToSmallCap'">uppercase</xsl:when>
          <xsl:otherwise>none</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$propname = 'CharacterDirection'">
        <!-- string "DefaultDirection" | string "LeftToRightDirection" | string "RightToLeftDirection" -->
        <xsl:value-of select="if( $property eq 'LeftToRightDirection') then 'ltr' else 'rtl'"/>
      </xsl:when>
      <xsl:when test="matches( $property, '^Color/' )">
	<xsl:variable name="ref-value" select="$idml2xml:Document//Color[ @Self eq $property ]"/>
	<xsl:value-of select="concat( $ref-value/@Space, '(', replace( $ref-value/@ColorValue, ' ', ',' ), ')' )"/>
      </xsl:when>
      <xsl:when test="$propname = 'FontStyle'">
      	<xsl:sequence select="replace( lower-case ($property), 'semi', '')"/>
      </xsl:when>
      <xsl:when test="$propname = 'Justification'">
        <!-- string "LeftAlign" | string "CenterAlign" | string "RightAlign" | string "LeftJustified" | string "RightJustified" | string "CenterJustified" | string "FullyJustified" | string "ToBindingSide" | string "AwayFromBindingSide" -->
      	<xsl:sequence 
            select="idml2xml:replaces( $property, 
                                       ('LeftAlign', 'left', 
                                        'CenterAlign', 'center',
                                        'RightAlign', 'right',
                                        'LeftJustified', 'left',
                                        'RightJustified', 'right',
                                        'CenterJustified', 'center',
                                        'FullyJustified', 'left',
                                        'ToBindingSide', 'left',
                                        'AwayFromBindingSide', 'left'
                                     ) )"/>
      </xsl:when>
      <xsl:when test="$propname = 'Name'">
      	<xsl:sequence select="idml2xml:StyleName( idml2xml:remove-type-from-property-value( $property ) )"/>
      </xsl:when>
      <xsl:when test="$propname eq 'ShadowColor'">
        <xsl:message select="'WARNING: attribute value for ShadowColor not implemented yet!'"/>
      </xsl:when>
      <xsl:when test="$propname = 'StrikeThru'">
      	<xsl:sequence select="'line-through'"/>
      </xsl:when>
      <xsl:otherwise>
      	<xsl:sequence select="idml2xml:remove-type-from-property-value( $property )"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="idml2xml:remove-type-from-property-value">
    <xsl:param name="propval" as="xs:string+"/>
    <xsl:value-of select="idml2xml:replaces( $propval, ('Color/', '') )"/>
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