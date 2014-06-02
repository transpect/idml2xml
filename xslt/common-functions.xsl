<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:letex = "http://www.le-tex.de/namespace"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
    exclude-result-prefixes = "xs idPkg letex"
>
  
  <xsl:include href="colors/colors.xsl"/>
  
  <xsl:key name="idml2xml:by-Self" match="*[@Self]" use="@Self" />
  
  <xsl:variable name="idml2xml:shape-element-names" as="xs:string+"
    select="('Rectangle', 'GraphicLine', 'Oval', 'Polygon')"/>
  <xsl:variable
    name="idml2xml:idml-content-element-names" 
    select="('Content', 'PageReference', 'idml2xml:control', 'idml2xml:genAnchor', $idml2xml:shape-element-names, 'TextFrame',
    'TextVariableInstance', 'idml2xml:tab', 'idml2xml:sep', 'HyperlinkTextSource')" 
    as="xs:string+" />
  <xsl:variable 
    name="idml2xml:idml-scope-terminal-names"
    select="($idml2xml:idml-content-element-names, 'Br', 'idml2xml:genFrame', 'Footnote', 'Table', 'Story', 'XmlStory', 'Cell', 'idml2xml:genCell', 'CharacterStyleRange')" 
    as="xs:string+" />

  <xsl:function name="letex:identical-self-object-suffix" as="xs:string">
    <xsl:param name="self-object" as="element(*)"/>
    <xsl:variable name="identical-Self-objects" select="key('idml2xml:by-Self', $self-object/@Self, root($self-object))" as="element(*)+" />
    <xsl:variable name="my-number" as="xs:integer"
      select="index-of(for $o in $identical-Self-objects return generate-id($o), generate-id($self-object))" />
    <xsl:sequence
      select="if ($my-number gt 1)
              then concat('_', string($my-number))
              else ''"/>
  </xsl:function>

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
    <xsl:sequence select="replace(replace($input, '\C', '_' ), '^(\I)', '_$1')"/>
  </xsl:function>

  <!-- Re-attach the removed style name strings, so that lookups work:
       (this is certainly not the most elegant approach. This whole style name
        normalization has to be redesigned) -->
  <xsl:function name="idml2xml:generate-style-name-variants" as="xs:string+">
    <xsl:param name="style-type" as="xs:string"/>
    <xsl:param name="style-name" as="xs:string"/>
    <xsl:sequence select="idml2xml:StyleNameEscape($style-name),
                          concat($style-type, '/', idml2xml:StyleNameEscape($style-name)),
                          concat($style-type, '/$ID/', idml2xml:StyleNameEscape($style-name)),
                          concat($style-type, '/$ID/[', idml2xml:StyleNameEscape($style-name), ']'),
                          concat('$ID/[', idml2xml:StyleNameEscape($style-name), ']')
                         "/>
  </xsl:function>
  
  
  <!-- Based-on styles -->
  
  <xsl:key name="idml2xml:style-by-Name"
    match="CellStyle | CharacterStyle | ObjectStyle | ParagraphStyle | TableStyle" 
    use="@Name" />
  
  <xsl:function name="idml2xml:style-ancestors-and-self" as="element(*)+">
    <xsl:param name="style" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$style/Properties/BasedOn">
        <xsl:message>ST: <xsl:value-of select="$style/@Self"/></xsl:message>
        <xsl:message >BO: <xsl:value-of select="$style/Properties/BasedOn"/></xsl:message>
        <xsl:message>KEY:
          <xsl:value-of select="key('idml2xml:style-by-Name', replace($style/Properties/BasedOn, '^ParagraphStyle/', ''), root($style))"/>
        </xsl:message>
        <xsl:sequence 
          select="$style, 
          idml2xml:style-ancestors-and-self(key('idml2xml:style-by-Name', replace($style/Properties/BasedOn, '^ParagraphStyle/', ''), root($style)))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$style"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:key name="idml2xml:BasedOn-by-value"
    match="BasedOn" 
    use="." />
  
  <xsl:function name="idml2xml:style-descendants-and-self" as="element(*)+">
    <xsl:param name="style" as="element(*)+"/>
    <xsl:variable name="based-on-this" select="key('idml2xml:BasedOn-by-value', $style/@Self, root($style[1]))"
      as="element(BasedOn)*"/>
    <xsl:choose>
      <xsl:when test="exists($based-on-this)">
        <xsl:sequence select="$style, idml2xml:style-descendants-and-self($based-on-this/../..)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$style"/>
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
    <xsl:param name="elt" as="node()" />
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
                          or $elt/self::idml2xml:genFrame[not(idml2xml:genFrame)]
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

    <!-- Message that an item will be removed will also be output for textframes containing continued stories -->

    <!-- workspace / spread -->
    <xsl:variable name="corresponding-spread" as="element(Spread)?" select="$item/ancestor::Spread"/>

    <xsl:choose>
      <xsl:when test="empty($corresponding-spread)">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <!-- unsupported Spread/@ItemTransform value -->
      <xsl:when test="substring($corresponding-spread/@ItemTransform, 0, 11) ne '1 0 0 1 0 '">
        <xsl:message
          select="'      WARNING: Spread for', local-name($item), string($item/@Self), 'does not fit standard settings. Item will be exported.'"/>
        <xsl:sequence select="true()"/>
      </xsl:when>

      <!-- item is a Group and the group got no transformation,
           then look for each child if its on workspace -->
      <xsl:when test="$item/self::Group and substring($item/@ItemTransform, 0, 8) eq '1 0 0 1'">
        <xsl:variable name="group-children" as="node()*"
          select="$item/*[not(matches(local-name(), 'Preference|Option'))]"/>
        <xsl:choose>
          <xsl:when
            test="every $item
                          in $group-children
                          satisfies not(idml2xml:item-is-on-workspace($item))">
            <xsl:sequence select="false()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="true()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- item is a textframe or an image -->
      <xsl:when test="local-name($item) = ('Rectangle', 'TextFrame')">
        <xsl:choose>
          <!-- unsupported TextFrame/@ItemTransform value -->
          <xsl:when test="substring($corresponding-spread/@ItemTransform, 0, 11) ne '1 0 0 1 0 '">
            <xsl:message
              select="'      WARNING:', local-name($item), 
                 'does not fit standard settings (in func idml2xml:item-is-on-workspace). Item will be exported.'"/>
            <xsl:sequence select="true()"/>
          </xsl:when>

          <!-- 'x' in Spread/@ItemTransform is set to 0 = center of the spread -->
          <!-- point zero 'y' is half size of spread height -->
          <xsl:otherwise>

            <!-- spread and page info -->
            <xsl:variable name="spread-binding" as="xs:string"
              select="if($corresponding-spread/@BindingLocation = 0) then 'left' else 'right'"/>
            <xsl:variable name="spread-x" as="xs:double"
              select="xs:double(tokenize($corresponding-spread/@ItemTransform, ' ')[5])"/>
            <!--        <xsl:variable name="spread-y" as="xs:double"
              select="xs:double(tokenize($corresponding-spread/@ItemTransform, ' ')[6])" />
-->

            <!-- item non-transformed coordinations -->
            <xsl:variable name="item-pathpoints" as="node()*"
              select="$item/Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType"/>
            <xsl:variable name="item-x-center" as="xs:double"
              select="xs:double(tokenize($item/@ItemTransform, ' ')[5])"/>
            <xsl:variable name="item-y" as="xs:double"
              select="xs:double(tokenize($item/@ItemTransform, ' ')[6])"/>
            <xsl:variable name="item-left" as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[1]/@Anchor, ' ' )[1] )"/>
            <xsl:variable name="item-top" as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[1]/@Anchor, ' ' )[2] )"/>
            <xsl:variable name="item-right" as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[3]/@Anchor, ' ' )[1] )"/>
            <xsl:variable name="item-bottom" as="xs:double"
              select="xs:double( tokenize( $item-pathpoints[3]/@Anchor, ' ' )[2] )"/>

            <xsl:variable name="group-x" as="xs:double"
              select="if($item/ancestor::Group) 
                      then sum(
                              for $group in $item/ancestor::Group
                               return xs:double( tokenize( $group/@ItemTransform, ' ' )[5] )
                            )
                      else 0"/>

<!--            <xsl:message select="'top:', $item-top, ' left:', $item-left, ' right:', $item-right, ' bottom:',$item-bottom"/>-->

            <xsl:variable name="item-real-center-x" as="xs:double"
              select="$spread-x + $item-x-center + $group-x"/>

            <xsl:variable name="item-real-left-x" as="xs:double"
              select="$item-real-center-x + $item-left"/>

            <xsl:variable name="item-real-right-x" as="xs:double"
              select="$item-real-center-x + $item-right"/>

            <!--        <xsl:variable name="corresponding-page" as="element(Page)?"
              select="if ($item/ancestor::Group)
              then $item/ancestor::Group[last()]/preceding-sibling::Page[1]
              else $item/preceding-sibling::Page[1]" />-->
            <xsl:variable name="page-width" as="xs:double"
              select="if( $corresponding-spread/Page[1]/@GeometricBounds ) 
              then xs:double(tokenize($corresponding-spread/Page[1]/@GeometricBounds, ' ')[4])
              else root($item)//DocumentPreference/@PageWidth"/>

            <xsl:variable name="left-page-available" as="xs:boolean"
              select="some $page 
              in $corresponding-spread/Page
              satisfies (xs:double(tokenize($page/@ItemTransform, ' ')[5]) lt 0.00001 and not($spread-binding eq 'left'))"/>

            <xsl:variable name="right-page-available" as="xs:boolean"
              select="some $page 
              in $corresponding-spread/Page
              satisfies xs:double(tokenize($page/@ItemTransform, ' ')[5]) ge -0.00001"/>

            <!--
        <xsl:if test="$item/@Self = ('u152')">
          <xsl:message select="'DEBUG ITEM Self:', xs:string($item/@Self)"/>
          <xsl:message select="'DEBUG item-real-left-x:', $item-real-left-x"/>
          <xsl:message select="'DEBUG item-real-center-x:', $item-real-center-x"/>
          <xsl:message select="'DEBUG item-real-right-x:', $item-real-right-x"/>
          <xsl:message select="'DEBUG spread-binding:', $spread-binding, 'spread-x:', $spread-x"/>
          <xsl:message select="'DEBUG page width:', $page-width"/>
          <xsl:message select="'DEBUG left/right page avail.:', $left-page-available, $right-page-available" />
        </xsl:if>
-->
            <xsl:variable name="causes" as="element(cause)+">
              <cause name="item outside single page (left side)" 
                present="{$item-real-right-x lt 0.0001 and not($left-page-available) and not($right-page-available) and count(root($item)//Spread/Page) eq 1}"/>
              <cause name="no page on left side" 
                present="{$item-real-right-x lt 0.0001 and not($left-page-available) and $right-page-available}"/>
              <cause name="no page on right side" 
                present="{$item-real-left-x gt -0.0001 and not($right-page-available) and $left-page-available}"/>
              <cause name="item placed outside of page left" 
                present="{$item-real-center-x lt 0.0001 and abs($item-real-right-x) gt $spread-x + abs($page-width)}"/>
              <cause name="item placed outside of page right" 
                present="{$item-real-center-x gt -0.0001 and abs($item-real-left-x) gt $spread-x + ($page-width)}"/>
            </xsl:variable>

            <!-- choose wether the item is on the workspace or not -->
            <xsl:choose>

              <!-- Item not on workspace -->
              <xsl:when test="$causes[@present = 'true']">
                <xsl:variable name="text-content" as="xs:string?"
                  select="substring(
                            string-join(root($item)//Story[@Self eq $item/@ParentStory]//Content/text(),''),
                            0,
                            200
                          )"/>
                <xsl:message
                  select="'      INFO: Removed', local-name($item), xs:string($item/@Self), '(not on workspace). REASON(s):', 
                          string-join($causes[@present = 'true']/@name, ', '),
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
        <xsl:message
          select="'      WARNING: Element', local-name($item),
                 'not yet supported in function idml2xml:item-is-on-workspace. Item will be exported.'"/>
        <xsl:sequence select="true()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="idml2xml:get-shape-top-coordinate" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:variable name="PathPoints" as="node()*"
      select="$shape-element/Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType"/>
    <xsl:sequence select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[2] )"/>
  </xsl:function>
  
  <xsl:function name="idml2xml:get-shape-right-coordinate" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:variable name="PathPoints" as="node()*"
      select="$shape-element/Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType"/>
    <xsl:sequence select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[1] )"/>
  </xsl:function>
  
  <xsl:function name="idml2xml:get-shape-bottom-coordinate" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:variable name="PathPoints" as="node()*"
      select="$shape-element/Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType"/>
    <xsl:sequence select="xs:double( tokenize( $PathPoints[3]/@Anchor, ' ' )[2] )"/>
  </xsl:function>
  
  <xsl:function name="idml2xml:get-shape-left-coordinate" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:variable name="PathPoints" as="node()*"
      select="$shape-element/Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType"/>
    <xsl:sequence select="xs:double( tokenize( $PathPoints[1]/@Anchor, ' ' )[1] )"/>
  </xsl:function>

  <xsl:function name="idml2xml:get-shape-width" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:variable name="CoordinateLeft" select="idml2xml:get-shape-left-coordinate($shape-element)" as="xs:double"/>
    <xsl:variable name="CoordinateRight" select="idml2xml:get-shape-right-coordinate($shape-element)" as="xs:double"/>
    <xsl:message select="$CoordinateRight, ':::', 'CoordinateRight'"/>
    <xsl:message select="$CoordinateLeft, ':::', 'CoordinateLeft'"/>
    <xsl:choose>
      <xsl:when test="$CoordinateLeft gt 0 and $CoordinateRight gt 0">
        <xsl:sequence select="$CoordinateRight - $CoordinateLeft"/>
      </xsl:when>
      <xsl:when test="$CoordinateLeft lt 0 and $CoordinateRight lt 0">
        <xsl:sequence select="abs($CoordinateLeft - $CoordinateRight)"/>
      </xsl:when>
      <xsl:when test="$CoordinateLeft lt 0 and $CoordinateRight gt 0">
        <xsl:sequence select="abs($CoordinateLeft) + $CoordinateRight"/>
      </xsl:when>
      <!-- shape transformed, unsupported -->
      <xsl:otherwise>
        <xsl:message select="concat('IDML2XML WARNING: Shape ', local-name($shape-element), ' (', $shape-element/@Self, ') with not yet implemented transformation settings.')"/>
        <xsl:sequence select="xs:double('0')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="idml2xml:get-shape-height" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:choose>
      <xsl:when test="idml2xml:get-shape-left-coordinate($shape-element)">
        <xsl:sequence select="idml2xml:get-shape-bottom-coordinate($shape-element) - idml2xml:get-shape-top-coordinate($shape-element)"/>
      </xsl:when>
      <!-- shape transformed, unsupported -->
      <xsl:otherwise>
        <xsl:message select="concat('IDML2XML WARNING: Shape ', local-name($shape-element), ' (', $shape-element/@Self, ') with not yet implemented transformation settings.')"/>
        <xsl:sequence select="xs:double('0')"/>
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
