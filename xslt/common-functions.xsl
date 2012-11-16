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
  
  <xsl:variable
    name="idml2xml:idml-content-element-names" 
    select="('TextVariableInstance', 'Content', 'Rectangle', 'PageReference', 'idml2xml:genAnchor', 'TextFrame')" 
    as="xs:string+" />
  <xsl:variable 
    name="idml2xml:idml-scope-terminal-names"
    select="($idml2xml:idml-content-element-names, 'Br', 'idml2xml:genFrame', 'Footnote', 'Table', 'Story', 'XmlStory', 'Cell', 'CharacterStyleRange')" 
    as="xs:string+" />

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
                            $stylename,
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
    <xsl:sequence select="not($elt/ancestor::*[idml2xml:is-scope-origin(.)]
                                              [some $a in ancestor::* satisfies ($a is $ancestor-elt)])" />
  </xsl:function>

  <xsl:function name="idml2xml:is-scope-origin" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:sequence select="   $elt/self::Cell 
                          or $elt/@aid:table eq 'cell' 
                          or $elt/self::Footnote
                          or $elt/self::Story
                          or $elt/self::XmlStory 
                          or $elt/@idml2xml:story
                          " />
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


  <!-- Document functions -->

  <xsl:function name="idml2xml:item-is-on-workspace">
    <xsl:param name="item" as="element(*)"/>

    <!-- @ItemTransform: (standard is 1 0 0 1 0 0) last two are x and y
         matrix: see idml-specification.pdf
    -->
    <!-- Coordinations of items with PathPointArray:
	 <PathPointArray>
	   <PathPoint Anchor="{$left} {$top}" LeftDirection="{$left} {$top}" RightDirection="{$left} {$top}"/>
	   <PathPoint Anchor="{$left} {$bottom}" LeftDirection="{$left} {$bottom}" RightDirection="{$left} {$bottom}"/>
	   <PathPoint Anchor="{$right} {$bottom}" LeftDirection="{$right} {$bottom}" RightDirection="{$right} {$bottom}"/>
	   <PathPoint Anchor="{$right} {$top}" LeftDirection="{$right} {$top}" RightDirection="{$right} {$top}"/>
	 </PathPointArray>
    -->

    <!-- workspace / spread -->
    <xsl:variable name="corresponding-spread" as="element(Spread)"
      select="$item/ancestor::Spread" />

    <xsl:choose>
      <!-- unsupported Spread/@ItemTransform value -->
      <xsl:when test="substring($corresponding-spread/@ItemTransform, 0, 11) ne '1 0 0 1 0 '">
	<xsl:message select="'      WARNING: Spread for', local-name($item), 'does not fit standard settings. Item will be exported.'"/>
	<xsl:sequence select="true()"/>
      </xsl:when>

      <!-- item is a Group and the group got no transformation, 
	   then look for each child if its on workspace -->
      <xsl:when test="$item/self::Group          (: and $item/@ItemTransform eq '1 0 0 1 0 0'  :)">
	<xsl:variable name="group-childs" as="node()*"
          select="$item/*[not(matches(local-name(), 'Preference|Option'))]"/>
	<xsl:choose>
	  <xsl:when test="every $item 
                          in $group-childs 
                          satisfies not(idml2xml:item-is-on-workspace($item))">
	    <xsl:sequence select="false()"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:sequence select="true()"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      
      <!-- item is a textframe -->
      <xsl:when test="local-name($item) = ('GraphicLine', 'Rectangle', 'TextFrame')">
	<xsl:choose>
	  <!-- unsupported TextFrame/@ItemTransform value -->
	  <xsl:when test="substring($corresponding-spread/@ItemTransform, 0, 11) ne '1 0 0 1 0 '">
	    <xsl:message select="'      WARNING:', local-name($item), 
				 'does not fit standard settings (in func idml2xml:item-is-on-workspace). Item will be exported.'"/>
	    <xsl:sequence select="true()"/>
	  </xsl:when>

	  <!-- 'x' in ItemTransform is set to 0, point x zero is binding right or binding left -->
	  <!-- point zero 'y' is half size of spread height -->
	  <xsl:otherwise>

	    <!-- spread and page info -->
	    <xsl:variable name="spread-binding" as="xs:string"
              select="if($corresponding-spread/@BindingLocation = 0) then 'left' else 'right'" />
	    <xsl:variable name="spread-x" as="xs:double"
              select="xs:double(tokenize($corresponding-spread/@ItemTransform, ' ')[5])" />
<!--	    <xsl:variable name="spread-y" as="xs:double"
              select="xs:double(tokenize($corresponding-spread/@ItemTransform, ' ')[6])" />
-->
	    <xsl:variable name="corresponding-page" as="element(Page)"
              select="if ($item/ancestor::Group)
		      then $item/ancestor::Group[last()]/preceding-sibling::Page[1]
		      else $item/preceding-sibling::Page[1]" />
	    <xsl:variable name="page-width" as="xs:double"
              select="if( $corresponding-page/@GeometricBounds ) 
		      then xs:double(tokenize($corresponding-page/@GeometricBounds, ' ')[4])
		      else root($item)//DocumentPreference/@PageWidth" />

	    <!-- item non-transformed coordinations -->
            <xsl:variable name="item-pathpoints" as="node()*"
              select="$item/Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType" />
            <xsl:variable name="item-x" as="xs:double"
              select="xs:double(tokenize($item/@ItemTransform, ' ')[5])" />
            <xsl:variable name="item-y" as="xs:double"
              select="xs:double(tokenize($item/@ItemTransform, ' ')[6])" />
            <xsl:variable name="item-left"  as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[1]/@Anchor, ' ' )[1] )" />
            <xsl:variable name="item-top" as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[1]/@Anchor, ' ' )[2] )" />
            <xsl:variable name="item-right" as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[3]/@Anchor, ' ' )[1] )"  />
            <xsl:variable name="item-bottom" as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[3]/@Anchor, ' ' )[2] )"  />
<!--            <xsl:message select="'top:', $item-top, ' left:',
		$item-left, ' right:', $item-right, ' bottom:',$item-bottom"/>-->

	    <xsl:variable name="indesign-real-item-topleft-x-coordinate" as="xs:double"
              select="$spread-x + $item-x + $item-left" />
<!--
<xsl:if test="$item/@Self eq 'uc96'">
  <xsl:message select="'indesign-real-item-topleft-x-coordinate:', $spread-x + $item-x + $item-left"/>
  <xsl:message select="'spread-binding:', $spread-binding, $spread-x"/>
  <xsl:message select="$indesign-real-item-topleft-x-coordinate, $spread-x + ($page-width *-1)"/>
</xsl:if>
-->
	    <!-- choose wether the item is on the workspace or not -->
	    <xsl:choose>
	      
	      <!-- Item not on workspace -->
	      <xsl:when test="$spread-binding eq 'right' and 
			        $indesign-real-item-topleft-x-coordinate lt $spread-x + ($page-width * -1 )
                              or
                              $spread-binding eq 'left' and 
			        ($item-x + $item-left) le $spread-x
			      or
			      $spread-binding eq 'left' and 
			        ($indesign-real-item-topleft-x-coordinate) gt $spread-x + $page-width">
		<xsl:variable name="text-content" as="xs:string?"
                  select="substring(
                            string-join($idml2xml:Document//Story[@Self eq $item/@ParentStory]//Content/text(),''),
                            0,
                            200
                          )"/>
		  <xsl:message 
                    select="'      INFO: Removed', local-name($item), xs:string($item/@Self), '(not on workspace). ',
		  	    if (normalize-space($text-content)) 
			      then concat('TEXT: ', $text-content) 
			    else ''"/>
		<xsl:sequence select="false()"/>
	      </xsl:when>

	      <!-- item is above or below spread -->
	      <!--
	      <xsl:when test="">
		<xsl:sequence select="false()"/>
	      </xsl:when>
	      -->

	      <!-- Item is on workspace-->
	      <xsl:otherwise>
		<xsl:sequence select="true()"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message select="'      WARNING: Element', local-name($item),
			     'not yet supported in function idml2xml:item-is-on-workspace. Item will be exported.'"/>
	<xsl:sequence select="true()"/>
      </xsl:otherwise>
    </xsl:choose>
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
