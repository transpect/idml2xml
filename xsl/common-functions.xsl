<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:tr="http://transpect.io"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://transpect.io/idml2xml"
    exclude-result-prefixes = "xs idPkg"
>
  
  <xsl:include href="http://transpect.io/xslt-util/colors/xsl/colors.xsl"/>
  
  <xsl:key name="idml2xml:by-Self" match="*[@Self]" use="@Self" />
  
  <!-- converts hidden page refs in toc to links pointing to page anchors as created by PageNames script -->
  <xsl:variable name="idml2xml:convert-hidden-toc-refs-to-hyperlinks" as="xs:boolean" select="false()"/>
  
  <xsl:variable name="idml2xml:shape-element-names" as="xs:string+"
    select="('Rectangle', 'GraphicLine', 'Oval', 'Polygon', 'MultiStateObject')"/>
  <xsl:variable
    name="idml2xml:idml-content-element-names-without-textSource" 
    select="('Content', 'PageReference', 'idml2xml:control', 'idml2xml:genAnchor', 'idml2xml:genTable', $idml2xml:shape-element-names, 'TextFrame',
    'TextVariableInstance', 'idml2xml:tab', 'idml2xml:sep', 'MathToolsML')" 
    as="xs:string+" />
  <xsl:variable
    name="idml2xml:idml-content-element-names" 
    select="($idml2xml:idml-content-element-names-without-textSource, 'CharacterStyleRange', 'HyperlinkTextSource')" 
    as="xs:string+" />
  <xsl:variable 
    name="idml2xml:idml-scope-terminal-names"
    select="($idml2xml:idml-content-element-names-without-textSource, 'Br', 'idml2xml:genFrame', 'Footnote', 'Table', 'Story', 'XmlStory', 'Cell', 
    'idml2xml:genCell', 'Group')" 
    as="xs:string+" />

  <!-- GI 2015-11-01: Created this function ad hoc as a replacement for predicates 
    [name() = $idml2xml:idml-scope-terminal-names]. Reason: After ExtractTagging, there may by custom tags for table cells.
    I didn’t analyze yet whether is-scope-terminal and is-scope-origin should mean the same thing (i.e., should
    return the same value for a given input, if input is an element). -->
  <xsl:function name="idml2xml:is-scope-terminal" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="$node/self::element()/name() = $idml2xml:idml-scope-terminal-names
                          or
                          $node/@aid:table = 'cell'"/>
  </xsl:function>

  <xsl:function name="tr:identical-self-object-suffix" as="xs:string">
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
    <xsl:param name="stylename" as="xs:string?"/>
    <!-- Convertes strings that originate from both ParagraphStyle/@Name and ParagraphStyle/@Selfor.
      ParagraphStyle/@Name is a Unicode literal while ParagraphStyle/@Self is hex-escaped. 
      This converts hex-escaped to unicode. It may go wrong if the unicode string already contains 
      what looks like percent encoding.
      tr:unescape-uri() replaces previous '%3a'→':' replacement for hierarchically organized styles.
      The previous ad-hoc replacement was introduced when tr:unescape-uri() did not exist yet. -->
    <xsl:if test="matches($stylename, '%(0[0-8BCEF]|1[0-9A-F])', 'i')">
      <xsl:message select="'Some characters invalid in XML 1.0: ', $stylename"/>
    </xsl:if>
    <xsl:sequence select="tr:unescape-uri(replace($stylename, '%(0[0-8BCEF]|1[0-9A-F])', '', 'i'))"/>
  </xsl:function>

  <xsl:function name="idml2xml:RemoveTypeFromStyleName" as="xs:string">
    <xsl:param name="stylename" as="xs:string"/>
    <xsl:sequence select="replace( idml2xml:substr( 'a', $stylename, '$ID/' ), 
                          '(Paragraph|Character|Table|Cell|Object)Style/|\[|\]',
                          '' )"/>
  </xsl:function>

  <xsl:function name="idml2xml:escape-id" as="xs:string">
    <xsl:param name="input" as="xs:string"/>
    <xsl:sequence select="replace(encode-for-uri((replace(replace($input, '\C', '_' ), '^(\I)', '_$1'))), '%', '_')"/>
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
    <!-- returns true if a Br comes first in a given context -->
    <xsl:sequence select="exists( 
                                  ($elt[not(self::Cell)]//*
                                    [idml2xml:is-scope-terminal(.)]
                                    [idml2xml:same-scope(., $elt)]
                                  )[position() = (if (last() eq 1) then 2 else 1)]
                                  /self::Br 
                                )" />
  </xsl:function>

  <xsl:function name="idml2xml:br-last" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <!-- returns true if a Br comes last in a given context or if it is the only Br.
    Treating single Brs as last ones is necessary because otherwise ParagraphBreakType="NextPage"
    will be attached to the wrong (the following) paragraph in idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br -->
    <xsl:sequence select="exists( 
                                  ($elt[not(self::Cell)]//*
                                    [idml2xml:is-scope-terminal(.)]
                                    [idml2xml:same-scope(., $elt)]
                                  )[last()]
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
    <xsl:variable name="prelim" as="xs:string*">
      <xsl:sequence select="$elt/name()"/>
      <xsl:sequence select="idml2xml:attr-hashes($elt)"/>
      <xsl:sequence select="for $p in $elt/Properties/* return (idml2xml:elt-signature($p), string($p))"/>
    </xsl:variable>
    <xsl:sequence select="string-join($prelim, '__')"/>
  </xsl:function>

  <xsl:function name="idml2xml:attr-hashes" as="xs:string*">
    <xsl:param name="elt" as="node()*" />
    <xsl:perform-sort>
      <xsl:sort/>
      <xsl:sequence select="for $a in $elt/(@* except (@srcpath | @xml:id)) return idml2xml:attr-hash($a)" />
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

  <xsl:function name="idml2xml:index-of" as="xs:integer*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="index-of(for $n in $nodes return generate-id($n), generate-id($node))"/>
  </xsl:function>

  <!-- Document functions -->

  <xsl:key name="idml2xml:corresponding-master-spread" match="MasterSpread" use="@Self"/>

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
      <xsl:when test="substring($corresponding-spread/@ItemTransform, 0, 9) ne '1 0 0 1 '">
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
          <xsl:when test="substring($corresponding-spread/@ItemTransform, 0, 9) ne '1 0 0 1 '">
            <xsl:message
              select="'      WARNING:', local-name($item), 
                 'does not fit standard settings (in func idml2xml:item-is-on-workspace). Item will be exported.'"/>
            <xsl:sequence select="true()"/>
          </xsl:when>
          <xsl:when test="count($item/Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType) lt 4">
            <xsl:sequence select="false()"/>
          </xsl:when>

          <!-- 'x' in Spread/@ItemTransform is set to 0 = center of the spread -->
          <!-- point zero 'y' is half size of spread height -->
          <xsl:otherwise>

            <!-- spread and page info. if page position (index) on spread is less than @BindingLocation it is a left page. 
                  therefore the following variable declaration is not really exact -->
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
            <!-- what if object is not on page 1 of a spread? there could be differently wide pages in one spread -->
            <xsl:variable name="page-width" as="xs:double"
              select="if( $corresponding-spread/Page[1]/@GeometricBounds ) 
              then xs:double(tokenize($corresponding-spread/Page[1]/@GeometricBounds, ' ')[4])
              else root($item)//DocumentPreference/@PageWidth"/>

<!--            <xsl:variable name="left-page-available" as="xs:boolean"
              select="some $page 
              in $corresponding-spread/Page
              satisfies (((xs:double(tokenize($page/@ItemTransform, ' ')[5])(: + xs:double(tokenize($page/@MasterPageTransform, ' ')[5]):)) lt 0.00001) 
                         and (not($spread-binding eq 'left') or (every  $mp in $corresponding-spread/Page satisfies ($mp[key('idml2xml:corresponding-master-spread', @AppliedMaster)[@PageCount = '1']]))))"/>
            <!-\- sometimes single masterpages are assigned to spreads with several pages. this case is handled here -\->

            <xsl:variable name="right-page-available" as="xs:boolean"
              select="some $page 
              in $corresponding-spread/Page
              satisfies ((xs:double(tokenize($page/@ItemTransform, ' ')[5])(: + xs:double(tokenize($page/@MasterPageTransform, ' ')[5]):)) ge -0.00001)"/>-->

         <xsl:variable name="left-page-available" as="xs:boolean"
              select="some $page in $corresponding-spread/Page satisfies ((index-of($corresponding-spread/Page/@Self, $page/@Self) -1) lt xs:double($corresponding-spread/@BindingLocation))"/>

            <xsl:variable name="right-page-available" as="xs:boolean"
              select="some $page in $corresponding-spread/Page satisfies ((index-of($corresponding-spread/Page/@Self, $page/@Self) -1) ge xs:double($corresponding-spread/@BindingLocation))"/>

        <!--<xsl:if test="$item/@Self eq 'u250'">
          <xsl:message select="'DEBUG ITEM Self:', xs:string($item/@Self)"/>
          <xsl:message select="'DEBUG item-real-left-x:', $item-real-left-x"/>
          <xsl:message select="'DEBUG item-real-center-x:', $item-real-center-x"/>
          <xsl:message select="'DEBUG item-real-right-x:', $item-real-right-x"/>
          <xsl:message select="'DEBUG spread-binding:', $spread-binding, 'spread-x:', $spread-x"/>
          <xsl:message select="'DEBUG page width:', $page-width"/>
          <xsl:message select="'DEBUG left/right page avail.:', $left-page-available, $right-page-available" />
        </xsl:if>-->


         <!-- if each spread only consists of a single page, e.g. a right one. the center of the spread has the coordinates 0,0. 
              In this case no left page exists, but objects may exist that have a negative x-value, because they are on the left side of the spread. For these cases the cause calculation doesn't make much sense-->
         <xsl:variable name="single-paged-doc" as="xs:boolean" select="if (every $spread in root($item)//Spread satisfies $spread/@PageCount eq '1') then true() else false()" />

         <xsl:variable name="causes" as="element(cause)+">
            <cause name="item outside single page (left side)" 
              present="{$item-real-right-x lt 0.0001 and $left-page-available and not($right-page-available) and count(root($item)//Spread/Page) eq 1 and 
                        (: full-width image :) not(abs($item-real-left-x) lt ($spread-x + abs($page-width) + root($item)//DocumentPreference/@DocumentBleedOutsideOrRightOffset))}"/>
            <cause name="no page on left side" 
              present="{$item-real-right-x lt 0.0001 and not($left-page-available) and $right-page-available and not($single-paged-doc)}"/>
            <cause name="no page on right side" 
              present="{$item-real-left-x gt -0.0001 and not($right-page-available) and $left-page-available and not($single-paged-doc)}"/>
            <cause name="item placed outside of page left" 
              present="{$item-real-center-x lt 0.0001 and abs($item-real-right-x) gt $spread-x + (abs($page-width) + root($item)//DocumentPreference/@DocumentBleedInsideOrLeftOffset)}"/>
            <cause name="item placed outside of page right" 
              present="{$item-real-center-x gt -0.0001 and abs($item-real-left-x) gt ($spread-x + ($page-width) + root($item)//DocumentPreference/@DocumentBleedOutsideOrRightOffset)}"/>
          </xsl:variable>

            <!-- choose whether the item is on the workspace or not -->
            <xsl:choose>

              <!-- Item not on workspace -->
              <xsl:when test="$causes[@present = 'true'] and not(idml2xml:is-on-workspace-because-we-know-better($item))">
                <xsl:variable name="text-content" as="xs:string?"
                  select="substring(
                            string-join(root($item)//Story[@Self eq $item/@ParentStory]//Content/text(),''),
                            0,
                            200
                          )"/>
                <xsl:message
                  select="'################### INFO: Removed', local-name($item), xs:string($item/@Self), '(not on workspace). REASON(s):', 
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
  
  <xsl:function name="idml2xml:is-on-workspace-because-we-know-better" as="xs:boolean">
    <xsl:param name="item" as="element(*)"/>
    <xsl:sequence select="false()"/>
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
    <xsl:sequence select="number( tokenize( $PathPoints[1]/@Anchor, ' ' )[1] )"/>
  </xsl:function>

  <xsl:function name="idml2xml:get-shape-width" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:variable name="CoordinateLeft" select="idml2xml:get-shape-left-coordinate($shape-element)" as="xs:double"/>
    <xsl:variable name="CoordinateRight" select="idml2xml:get-shape-right-coordinate($shape-element)" as="xs:double"/>
    <xsl:choose>
      <xsl:when test="$CoordinateLeft ge 0 and $CoordinateRight ge 0">
        <xsl:sequence select="abs($CoordinateRight - $CoordinateLeft)"/>
      </xsl:when>
      <xsl:when test="$CoordinateLeft le 0 and $CoordinateRight le 0">
        <xsl:sequence select="abs($CoordinateLeft - $CoordinateRight)"/>
      </xsl:when>
      <xsl:when test="$CoordinateLeft le 0 and $CoordinateRight ge 0">
        <xsl:sequence select="abs($CoordinateLeft) + $CoordinateRight"/>
      </xsl:when>
      <!-- shape transformed, unsupported -->
      <xsl:otherwise>
        <xsl:message select="concat('IDML2XML WARNING: Shape ', local-name($shape-element), ' (', $shape-element/@Self, ') with not yet implemented transformation settings.')"/>
        <xsl:sequence select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="idml2xml:get-shape-height" as="xs:double">
    <xsl:param name="shape-element" as="element()"/>
    <xsl:choose>
      <xsl:when test="string(idml2xml:get-shape-left-coordinate($shape-element)) != 'NaN'">
        <!-- GI 2017-04-14: Guiseppe Bonelli suggested that we remove this xsl:choose altogether since
          it treated the (acceptable) value of 0 as an error. Cautiously only excluding NaN which 
          wouldn’t have been returned anyway as long as the xs:double typecast was in the function. -->
        <xsl:sequence select="abs(idml2xml:get-shape-bottom-coordinate($shape-element) - idml2xml:get-shape-top-coordinate($shape-element))"/>
      </xsl:when>
      <!-- shape transformed, unsupported -->
      <xsl:otherwise>
        <xsl:message select="concat('IDML2XML WARNING: Shape ', local-name($shape-element), ' (', $shape-element/@Self, ') with not yet implemented transformation settings.')"/>
        <xsl:sequence select="0"/>
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
