<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
    version="2.0"
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs = "http://www.w3.org/2001/XMLSchema"
    xmlns:xhtml = "http://www.w3.org/1999/xhtml"
    xmlns:aid = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5 = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml = "http://www.le-tex.de/namespace/idml2xml"
    exclude-result-prefixes = "#all"
    >

  <!-- 
       xmlns:hub	= "http://www.le-tex.de/namespace/hubformat"
       xmlns="http://www.le-tex.de/namespace/hubformat"
  -->

  <xsl:variable 
      name="hubformat-elementnames-whitelist"
      select="('anchor', 'book', 'para', 'informaltable', 'table', 'tgroup', 
               'colspec', 'tbody', 'row', 'entry', 'mediaobject', 
               'imageobject', 'imagedata', 'phrase', 'emphasis', 'sidebar')"/>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-add-properties -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="idml2xml:doc" mode="idml2xml:XML-Hubformat-add-properties">
    <book>
      <xsl:apply-templates select="@TOCStyle_Title | node()" mode="#current"/>
    </book>
  </xsl:template>

  <xsl:template match="idml2xml:genPara |
                       idml2xml:genSpan 
                       (:
                       idml2xml:RootCharacterStyleGroup | 
		       idml2xml:RootParagraphStyleGroup |
		       idml2xml:RootCellStyleGroup |
		       idml2xml:RootTableStyleGroup |
		       idml2xml:RootObjectStyleGroup |
                       idml2xml:CharacterStyle |
                       idml2xml:CharacterStyle |
                       idml2xml:ParagraphStyle |
                       idml2xml:CellStyle |
                       idml2xml:TableStyle 
                       :)" 
		mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:copy>
      <xsl:if test="$hubformat-add-properties eq 1">
        <xsl:call-template name="add-properties"/>
      </xsl:if>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="add-properties">
    <xsl:param name="context" select="." />
    <xsl:variable name="style-type" as="xs:string">
      <xsl:choose>
        <xsl:when test="local-name ($context) eq 'genPara'">ParagraphStyle</xsl:when>
        <xsl:when test="local-name ($context) eq 'genSpan'">CharacterStyle</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="local-name()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="style-name" as="xs:string">
      <xsl:choose>
        <xsl:when test="local-name ($context) eq 'genPara'">
          <xsl:value-of select="$context/@aid:pstyle"/>
        </xsl:when>
        <xsl:when test="local-name ($context) eq 'genSpan'">
          <xsl:value-of select="$context/@aid:cstyle"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$context/@Name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- should be a presolved universal variable ... -->
    <xsl:variable 
        name="style-node"
        select="$idml2xml:Document/
                descendant::*[local-name() eq $style-type and @Name eq $style-name]" as="element(*)?"/>
    <xsl:variable 
        name="style-name-based-on"
        select="if ($style-node/Properties/BasedOn[matches(., concat('^', $style-type ) )]) 
                then replace($style-node/Properties/BasedOn[matches(., concat('^', $style-type ) )], '^ParagraphStyle/', '')
                else ()" as="xs:string?"/>
    <xsl:variable 
        name="style-node-based-on"
        select="if ($style-name-based-on ) 
                then $idml2xml:Document/
                     descendant::*[local-name() eq $style-type and @Name eq $style-name-based-on]
                else ()" as="element(*)?"/>
    <xsl:for-each 
        select="$style-node/@*[not (local-name() eq 'Name')] union $style-node-based-on/@*[not (local-name() eq 'Name')]">
      <xsl:sequence select="idml2xml:hubformat-add-property(current())"/>
    </xsl:for-each>
  </xsl:template>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-extract-frames -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- must handle frames in frames! -->
  <xsl:template match="*[@*:pstyle or @*:AppliedParagraphStyle][.//idml2xml:genFrame[idml2xml:same-scope(., current())]]" mode="idml2xml:XML-Hubformat-extract-frames">
    <xsl:variable name="frames" as="element(idml2xml:genFrame)+">
      <xsl:sequence select=".//idml2xml:genFrame[idml2xml:same-scope(., current())]"/>
    </xsl:variable>
    <xsl:variable name="frames-after-text" select="$frames[not(idml2xml:text-after(., current()))]" as="element(idml2xml:genFrame)*" />
    <xsl:apply-templates select="$frames except $frames-after-text"  mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
    <xsl:apply-templates select="$frames-after-text"  mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
  </xsl:template>

  <xsl:function name="idml2xml:text-after" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:param name="ancestor" as="element(*)" />
    <xsl:sequence select="matches(
                            string-join($ancestor//text()[. &gt;&gt; $elt] except $ancestor//idml2xml:genFrame//text(), ''),
                            '\S'
                          )" />
  </xsl:function>

  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames">
    <idml2xml:genAnchor id="{generate-id()}"/>
  </xsl:template>

  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames-genFrame">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="linkend" select="generate-id()" />
      <xsl:apply-templates mode="idml2xml:XML-Hubformat-extract-frames" />
    </xsl:copy>
  </xsl:template>


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-remap-para-and-span -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


  <xsl:variable name="id-prefix" select="'id_'" as="xs:string"/>

  <xsl:template match="idml2xml:genPara" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable 
        name="style" select="if (@aid:pstyle ne '') then @aid:pstyle else 'Standard'"
        as="xs:string"/>
    <para>
      <xsl:attribute name="role" select="idml2xml:StyleName( $style )" />
      <xsl:apply-templates select="@* except (@pstyle|@aid:pstyle )" mode="#current"/>
      <xsl:if test="HyperlinkTextDestination[1]/@DestinationUniqueKey ne ''">
        <xsl:attribute name="xml:id" select="concat ($id-prefix, HyperlinkTextDestination[1]/@DestinationUniqueKey)"/>
      </xsl:if>
      <!-- set anchor for hyperlink -->
      <xsl:if test="count (HyperlinkTextDestination) gt 1">
        <xsl:for-each select="HyperlinkTextDestination[position() ne 1]/@DestinationUniqueKey">
          <phrase xml:id="{concat ($id-prefix,.)}"/>
        </xsl:for-each>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </para>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[
                         not(
                           (
                             exists(Rectangle)
                             or
                             exists(idml2xml:genFrame)
                           ) 
                           or 
                           @aid:table = ('table')
                         )
                       ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="role" select="idml2xml:StyleName( @aid:cstyle )"/>
    <xsl:choose>
      <xsl:when test="$role = ('Nocharacterstyle', 'idml2xml:default') and not(text()[matches(., '\S')]) and count(*) gt 0 and count(*) eq count(PageReference union HyperlinkTextSource)">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:when test="$role = ('Nocharacterstyle', 'idml2xml:default') and not(text()[matches(., '\S')]) and count(* except idml2xml:genAnchor) eq 0">
        <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
      </xsl:when>
      <xsl:when test="$role = ('Nocharacterstyle', 'idml2xml:default') and text() and count(* except idml2xml:genAnchor) eq 0">
        <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        <xsl:apply-templates select="node() except idml2xml:genAnchor" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="idml2xml:genAnchor">
          <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        </xsl:if>
        <phrase role="{$role}">
          <xsl:variable name="emph-atts" as="attribute(*)*">
            <xsl:apply-templates select="@* except @aid:cstyle" mode="#current"/>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="exists($emph-atts)">
              <emphasis>
                <xsl:sequence select="$emph-atts" />
                <xsl:apply-templates select="node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
              </emphasis>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </phrase>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="idml2xml:genAnchor" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor id="{$id-prefix}{@*:id}" />
  </xsl:template>

  <xsl:template match="@linkend" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="linkend" select="concat ($id-prefix, .)" />
  </xsl:template>

  <xsl:template match="idml2xml:genFrame" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <sidebar remap="{@idml2xml:elementName}">
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </sidebar>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[ not( descendant::node()[self::text()] ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"
		priority="-1">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- May this be safely discarded under any circumstance? -->
  <xsl:template match="TextVariableInstance" mode="idml2xml:XML-Hubformat-remap-para-and-span" />


<!--  <xsl:template match="idml2xml:CharacterStyleRange[ ( idml2xml:Br  and  count(*) eq 1 )  or  
		       ( idml2xml:Br  and  idml2xml:Content 	and  not( idml2xml:Content/node() )
		       and count(*) eq 2 ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:if test="not( following::*[1][ self::idml2xml:ParagraphStyleRange ] )">
      <xsl:apply-templates mode="#current"/>
    </xsl:if>
  </xsl:template>-->

  <xsl:template match="PageReference" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <indexterm>
    <xsl:for-each select="tokenize( @ReferencedTopic, '(d1)?Topicn' )">
      <xsl:choose>
	<xsl:when test="position() eq 1  or  current() eq ''"/>
	<xsl:when test="position() eq 2">
	  <primary>
	    <xsl:value-of select="current()"/>
	  </primary>
	</xsl:when>
	<xsl:when test="position() eq 3">
	  <secondary>
	    <xsl:value-of select="current()"/>
	  </secondary>
	</xsl:when>
	<xsl:when test="position() eq 4">
	  <tertiary>
	    <xsl:value-of select="current()"/>
	  </tertiary>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message select="'WARNING: PageReference / sub-indexterm not processed:', ."/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </indexterm>
  </xsl:template>
  
  <xsl:template match="idml2xml:newline"
    mode="idml2xml:XML-Hubformat-remap-para-and-span" />
  
  <xsl:template match="	Root |
		       idml2xml:Content | 
		       idml2xml:Document | 
		       idml2xml:genDoc |
		       idml2xml:InCopyExportOption |
		       idml2xml:Story | 
		       idml2xml:StoryPreference
		       " mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="idml2xml:genDoc[ node() ]
                       [ not (descendant::*[local-name() eq 'genPara']) and
                         preceding-sibling::*[1][self::idml2xml:newline] and
                         following-sibling::*[1][self::idml2xml:newline]
                       ]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <para>
      <xsl:attribute 
          name="role" 
          select="if (preceding::*[self::idml2xml:genPara])
                  then preceding::*[self::idml2xml:genPara][1]/@aid:pstyle
                  else following::*[self::idml2xml:genPara][1]/@aid:pstyle"/>
      <xsl:apply-templates mode="#current"/>
    </para>
  </xsl:template>

  <xsl:template match="idml2xml:ParagraphStyleRange[
                       count(*) eq 1 and idml2xml:genPara
                       ]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

<!--  <xsl:template match="idml2xml:genPara[@aid:pstyle='Bild']"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    
  </xsl:template>-->

  <xsl:template 
    match="@idml2xml:* " 
    mode="idml2xml:XML-Hubformat-remap-para-and-span" 
    />

  <xsl:template 
    match="@*[name() = $dimensional-attributes]" 
    mode="idml2xml:XML-Hubformat-remap-para-and-span" 
    >
    <!-- convert InDesign's pt to twips: -->
    <xsl:attribute name="{name()}" select="xs:double(.) * 20.0" />
  </xsl:template>

  <xsl:variable name="dimensional-attributes" select="('margin-left', 'text-indent')" as="xs:string+" />


  <!-- BEGIN: tables -->

  <xsl:template match="idml2xml:*[*[@aid:table='table']]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="cell-src-name" select="'genCell'" />
    <xsl:variable name="colspan-src-name" select="'ccols'" />
    <xsl:variable name="rowspan-src-name" select="'crows'" />
    <xsl:variable name="var-cols" select="xs:integer(idml2xml:genSpan[@aid:table='table']/@aid:tcols)" />
    <xsl:variable name="var-table">
      <xsl:for-each select="idml2xml:make-rows( $var-cols, 
			    descendant::*[local-name()=$cell-src-name][1], 
			    number(descendant::*[local-name()=$cell-src-name][1]/@*[local-name()=$colspan-src-name]), 
			    0, 
			    'true',
			    $cell-src-name,
			    $colspan-src-name,
			    $rowspan-src-name
			    )/descendant-or-self::*:row">
	<xsl:copy>
	  <xsl:sequence select="*[local-name()=$cell-src-name]" />
	</xsl:copy>
      </xsl:for-each>
    </xsl:variable>
    <xsl:element name="informaltable">
      <xsl:element name="tgroup">
	<xsl:attribute name="cols" select="$var-cols" />
	<xsl:for-each select="1 to $var-cols">
	  <xsl:element name="colspec">
	    <xsl:attribute name="colname" select="concat( 'c', current() )"/>
	  </xsl:element>
	</xsl:for-each>
	<xsl:element name="tbody">
	    <xsl:apply-templates select="$var-table" mode="#current" />
	</xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="idml2xml:genCell[@aid:table='cell']" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="cumulated-cols" select="xs:integer(@cumulated-cols)" />
    <xsl:variable name="colspan" select="xs:integer(@aid:ccols)" />
    <xsl:variable name="rowspan" select="xs:integer(@aid:crows)" />
    <entry>
      <xsl:if test="$colspan=1">
	<xsl:attribute name="colname" select="concat('c', $cumulated-cols - $colspan + 1)" />
      </xsl:if>
      <xsl:if test="$colspan gt 1">
	<xsl:attribute name="namest" select="concat('c', $cumulated-cols - $colspan + 1)" />
	<xsl:attribute name="nameend" select="concat('c', $cumulated-cols)" />
      </xsl:if>
      <xsl:if test="$rowspan gt 1">
	<xsl:attribute name="morerows" select="$rowspan - 1" />
      </xsl:if>
      <xsl:attribute name="role" select="@aid:pstyle"/>
      <xsl:apply-templates mode="#current"/>
    </entry>
  </xsl:template>
  
  <xsl:function name="idml2xml:make-rows">
    <xsl:param name="var-cols" as="xs:double" />
    <xsl:param name="var-current-cell" as="element()*" />
    <xsl:param name="var-cumulated-cols" as="xs:double" />
    <xsl:param name="var-overlap" as="xs:integer*" />
    <xsl:param name="var-starts" as="xs:string" />
    <xsl:param name="cell-src-name" as="xs:string" />
    <xsl:param name="colspan-src-name" as="xs:string" />
    <xsl:param name="rowspan-src-name" as="xs:string" />
    <xsl:variable name="var-new-overlap" as="xs:integer*">
      <xsl:choose>
	<xsl:when test="$var-starts = 'false'">
	  <xsl:for-each select="subsequence($var-overlap, 1)">
	    <xsl:variable name="decrement" select=". - 1" as="xs:integer"/>
	    <xsl:if test="$decrement gt 0">
	      <xsl:value-of select=". - 1" />
	    </xsl:if>
	  </xsl:for-each>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:sequence select="$var-overlap" />
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="var-cumulated-overlap" as="xs:integer*">
      <xsl:value-of select="count(subsequence($var-new-overlap, 1)[. gt 0])"/>
    </xsl:variable>
    <xsl:if test="($var-current-cell ne '') or exists($var-current-cell/following-sibling::*[local-name()=$cell-src-name])">
      <xsl:element name="row">
	<xsl:sequence select="idml2xml:cells2row($var-cols, $var-current-cell, $var-cumulated-overlap + number($var-current-cell/@*[local-name()=$colspan-src-name]), $var-new-overlap, $cell-src-name, $colspan-src-name, $rowspan-src-name)" />
      </xsl:element>
    </xsl:if>
  </xsl:function>

  <xsl:function name="idml2xml:cells2row">
    <xsl:param name="var-cols" as="xs:double" />
    <xsl:param name="var-current-cell" as="element()*" />
    <xsl:param name="var-cumulated-cols" as="xs:double" />
    <xsl:param name="var-overlap" as="xs:integer*" />
    <xsl:param name="cell-src-name" as="xs:string" />
    <xsl:param name="colspan-src-name" as="xs:string" />
    <xsl:param name="rowspan-src-name" as="xs:string" />
    <xsl:variable name="var-new-overlap" as="xs:integer*">
      <xsl:sequence select="$var-overlap, if ($var-current-cell/@*[local-name()=$rowspan-src-name] ne '1') then idml2xml:for-loop(1, xs:integer($var-current-cell/@*[local-name()=$colspan-src-name]), xs:integer($var-current-cell/@*[local-name()=$rowspan-src-name])) else 0" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$var-cumulated-cols eq $var-cols">
	<xsl:for-each select="$var-current-cell">
	  <xsl:copy>
	    <xsl:attribute name="cumulated-cols" select="$var-cumulated-cols" />
	    <xsl:copy-of select="@*|node()" />
	  </xsl:copy>
	</xsl:for-each>
	<xsl:sequence select="idml2xml:make-rows($var-cols, $var-current-cell/following-sibling::*[local-name()=$cell-src-name][1], number($var-current-cell/following-sibling::*[local-name()=$cell-src-name][1]/@*[local-name()=$colspan-src-name]), $var-new-overlap, 'false', $cell-src-name, $colspan-src-name, $rowspan-src-name)" />
      </xsl:when>
      <xsl:when test="$var-cumulated-cols lt $var-cols">
	<xsl:for-each select="$var-current-cell">
	  <xsl:copy>
	    <xsl:attribute name="cumulated-cols" select="$var-cumulated-cols" />
	    <xsl:copy-of select="@*|node()" />
	  </xsl:copy>
	</xsl:for-each>
	<xsl:sequence select="idml2xml:cells2row($var-cols, $var-current-cell/following-sibling::*[local-name()=$cell-src-name][1], $var-cumulated-cols + number($var-current-cell/following-sibling::*[local-name()=$cell-src-name][1]/@*[local-name()=$colspan-src-name]), $var-new-overlap, $cell-src-name, $colspan-src-name, $rowspan-src-name)" />
      </xsl:when>
      <xsl:when test="$var-cumulated-cols gt $var-cols">
	<xsl:message terminate="no">Error: <xsl:value-of select="$var-cumulated-cols" /> cells in row, but only <xsl:value-of select="$var-cols" /> are allowed.</xsl:message>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="idml2xml:for-loop">
    <xsl:param name="from" as="xs:integer" />
    <xsl:param name="to" as="xs:integer" />
    <xsl:param name="do" />
    <xsl:choose>
      <xsl:when test="$from eq $to">
	<xsl:sequence select="$do" />
      </xsl:when>
      <xsl:otherwise>
	<xsl:sequence select="$do" />
	<xsl:sequence select="idml2xml:for-loop($from, $to - 1, $do)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- END: tables -->

  <xsl:template match="HyperlinkTextDestination | 
                       HyperlinkTextSource"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>


  <!-- figures -->
  <xsl:template match="Rectangle[not(@idml2xml:rectangle-embedded-source='true')]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <para>
      <mediaobject>
        <imageobject>
          <imagedata fileref="{.//@LinkResourceURI}"/>
        </imageobject>
      </mediaobject>
    </para>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[Rectangle]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="idml2xml:XmlStory" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"/>
  

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-cleanup-paras-and-br -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  <xsl:template match="phrase[ parent::p[count(*) eq 1 ] ]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="phrase[@role='br'][ following-sibling::*[ self::para ] ] |
		       phrase[@role='br'][ not(following-sibling::*) and parent::para ]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>

  <xsl:template match="row[not(node())]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:message select="'INFO: Removed empty element row.'"/>
  </xsl:template>

  <xsl:template match="para[parent::para]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <phrase role="idml2xml-para {@role}">
      <xsl:apply-templates select="@* except @role | node()" mode="#current"/>
    </phrase>
  </xsl:template>

  <xsl:template 
      match="@*:AppliedParagraphStyle | @*:AppliedCharacterStyle" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" />

  <xsl:template 
      match="*[not( local-name() = $hubformat-elementnames-whitelist )]" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:variable name="content" select="string-join(.,'')"/>
    <xsl:message>
      INFO: Removed non-hub element <xsl:value-of select="local-name()"/>
      <xsl:if test="$content ne ''">
        ===
        Text content: <xsl:value-of select="$content"/>
        ===</xsl:if>
    </xsl:message>
  </xsl:template>

</xsl:stylesheet>