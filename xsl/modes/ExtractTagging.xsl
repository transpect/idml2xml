<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
  xmlns:aid		= "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5	= "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg	=	"http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  xmlns:xlink	= "http://www.w3.org/1999/xlink"
  exclude-result-prefixes="aid5 aid xs"
>

  <!--== mode: idml2xml:ExtractTagging ==-->
	
  <xsl:template match="Document" mode="idml2xml:ExtractTagging">
    <idml2xml:doc>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="page_width" as="xs:double?" select="number(replace(descendant::*[self::idml2xml:sidebar[@remap = 'Page']][1]/@idml2xml:width, '\p{L}+$', ''))"/>
      <xsl:variable name="page_margins"  as="xs:string*" select="tokenize(replace(descendant::idml2xml:sidebar[@remap = 'Page'][1]/@idml2xml:margin, '\p{L}', ''), ' ')"/>
      <xsl:if test="$page_width castable as xs:double and $page_margins[2] castable as xs:double and $page_margins[4] castable as xs:double">
        <xsl:attribute name="TypeAreaWidth" select="$page_width - number($page_margins[2]) - number($page_margins[4])"/>
      </xsl:if>
      <xsl:copy-of select="(idPkg:Graphic, idPkg:Styles, idml2xml:hyper, idml2xml:index, idml2xml:indexterms, idml2xml:lang, idml2xml:cond)" />
      <xsl:apply-templates select="XmlStory" mode="#current"/>
      <xsl:variable name="processed-stories" as="xs:string*">
        <xsl:apply-templates select="XmlStory" mode="idml2xml:ExtractTagging-gather-IDs"/>
      </xsl:variable>
      <xsl:apply-templates select="  TextFrame/Story[not(@Self = distinct-values($processed-stories))] 
                                   | *[name() = $idml2xml:shape-element-names] 
                                   | XMLElement" mode="#current"/>
    </idml2xml:doc>
  </xsl:template>

  <xsl:template match="*" mode="idml2xml:ExtractTagging-gather-IDs">
    <xsl:apply-templates select="* union @*" mode="#current" />
  </xsl:template>
  <xsl:template match="@*" mode="idml2xml:ExtractTagging-gather-IDs" />
  <xsl:template match="text()" mode="idml2xml:ExtractTagging-gather-IDs" />

  <xsl:template match="@XMLContent[not(ancestor::Story[1]/@Self eq current())]" mode="idml2xml:ExtractTagging-gather-IDs">
    <xsl:apply-templates select="root(.)/Document/Story[@Self eq current()]" mode="#current"/>
  </xsl:template>

  <xsl:template match="Story" mode="idml2xml:ExtractTagging-gather-IDs">
    <xsl:sequence select="@Self" />
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="XMLElement[TextFrame/Story][every $c in * satisfies ($c/self::TextFrame or $c/self::XMLAttribute)]" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

	<xsl:template match="XMLElement" mode="idml2xml:ExtractTagging">
		<xsl:variable name="ElementFullName" select="replace( idml2xml:substr( 'a', @MarkupTag, 'XMLTag/' ), '%3a', ':' )" />
		<xsl:variable name="ElementName" select="idml2xml:substr( 'a', $ElementFullName, 'XMLTag/' )" />
		<xsl:variable name="ElementSpace" select="idml2xml:substr( 'b', $ElementName, ':' )" />
		<xsl:element name="{ $ElementFullName }" 
      namespace="{if (contains( $ElementName, ':' ) ) then /Document/idml2xml:namespaces/ns[ @short = $ElementSpace ]/@space  else  ''}">

      <xsl:apply-templates select="@*" mode="idml2xml:ExtractAttributes" />
      <xsl:apply-templates select="ancestor::Story[1]/parent::TextFrame/@idml2xml:layer" mode="idml2xml:ExtractAttributes"/>
      <xsl:apply-templates select="(XMLAttribute, Properties, Table)" mode="idml2xml:ExtractAttributes"/>
      <xsl:if test="XMLAttribute[@Name eq 'aid:pstyle']">
        <xsl:apply-templates select="(ancestor::ParagraphStyleRange | ../ancestor::XMLElement)[last()]" mode="idml2xml:ExtractAttributes"/>
      </xsl:if>
      <xsl:if test="XMLAttribute[@Name eq 'aid:cstyle']">
        <xsl:apply-templates select="ancestor::CharacterStyleRange[1]" mode="idml2xml:ExtractAttributes"/>
      </xsl:if>
      <!-- ancestor::XMLElement[1] is here for the following reason:
           If Cell was preceded by XMLElement when looking upwards the ancestor axis, do nothing. -->
      <xsl:apply-templates select="(ancestor::Cell[1] | ancestor::XMLElement[1])[last()]" mode="idml2xml:ExtractAttributes"/>


      <xsl:if test="parent::Story or parent::XmlStory">
        <xsl:attribute name="idml2xml:story" select="../@Self" />
      </xsl:if>

      <xsl:apply-templates mode="#current"/>
		</xsl:element>
	</xsl:template>

  <xsl:template match="*" mode="idml2xml:ExtractAttributes" />

  <xsl:template match="Properties" mode="idml2xml:ExtractAttributes">
    <xsl:copy-of select="." />
  </xsl:template>


  <xsl:template match="ParagraphStyleRange | CharacterStyleRange" mode="idml2xml:ExtractAttributes">
    <xsl:apply-templates select="@* | Properties" mode="#current" />
  </xsl:template>

  <xsl:template match="@*" mode="idml2xml:ExtractAttributes">
    <xsl:copy-of select="." />
  </xsl:template>

  <xsl:template match="@MarkupTag" mode="idml2xml:ExtractAttributes" />

  <xsl:template match="CharacterStyleRange/@AppliedCharacterStyle[. eq 'CharacterStyle/$ID/[No character style]']" mode="idml2xml:ExtractAttributes" />

<xsl:template match="@AppliedParagraphStyle | @AppliedCharacterStyle | @idml2xml:layer" mode="idml2xml:ExtractAttributes">
    <xsl:attribute name="idml2xml:{local-name()}" select="idml2xml:RemoveTypeFromStyleName( . )"/>
  </xsl:template>

  <xsl:template match="XMLAttribute[starts-with(@Name, 'xmlns:')]" mode="idml2xml:ExtractAttributes">
    <xsl:namespace name="{idml2xml:substr('a', @Name, ':')}" select="@Value" />
  </xsl:template>

  <xsl:template match="XMLAttribute" mode="idml2xml:ExtractAttributes">
    <xsl:variable name="AttrName" select="idml2xml:substr( 'a', @Name, ':' )" as="xs:string+"/>
    <xsl:variable name="AttrSpace" select="idml2xml:substr( 'b', @Name, ':' )" as="xs:string+"/>
    <xsl:choose>
      <xsl:when test="matches( @Name, ':' )  and  ( /Document/idml2xml:namespaces/ns[ @short = $AttrSpace ]/@space != '' )">
        <xsl:attribute name="{ @Name }" select="@Value" namespace="{ /Document/idml2xml:namespaces/ns[ @short = $AttrSpace ]/@space }" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="{ $AttrName }" select="@Value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Table" mode="idml2xml:ExtractAttributes">
    <xsl:attribute name="aid:table" select="'table'"/>
    <xsl:attribute name="aid:tcols" select="@ColumnCount"/>
    <xsl:attribute name="aid:trows" select="count( Row )"/>
    <xsl:attribute name="aid:header-row-count" select="@HeaderRowCount"/>
    <xsl:attribute name="aid:body-row-count" select="@BodyRowCount"/>
    <xsl:attribute name="aid:footer-row-count" select="@FooterRowCount"/>
    <xsl:attribute name="aid5:tablestyle" select="idml2xml:StyleName(@AppliedTableStyle)"/>
    <xsl:attribute name="idml2xml:width" select="sum(Column/@SingleColumnWidth/number())"/>
    <xsl:copy-of select="ancestor::Story[1]/parent::TextFrame/@idml2xml:objectstyle" />
  </xsl:template>

  <xsl:template match="Cell" mode="idml2xml:ExtractAttributes">
    <xsl:attribute name="aid:table" select="'cell'"/>
    <xsl:attribute name="aid:ccols" select="@ColumnSpan"/>
    <xsl:attribute name="aid:crows" select="@RowSpan"/>
    <xsl:attribute name="aid:colname" select="tokenize(@Name,':')[1]"/>
    <xsl:attribute name="aid:rowname" select="tokenize(@Name,':')[2]"/>
    <xsl:attribute name="aid:ccolwidth" 
      select="preceding::Column[ @Name eq tokenize( current()/@Name, ':' )[1] ][1]/@SingleColumnWidth"/>
    <xsl:attribute name="aid5:cellstyle" select="idml2xml:StyleName(@AppliedCellStyle)"/>
    <xsl:apply-templates select="@*" mode="#current"/>
  </xsl:template>
  
  
  <!-- XMLElement with referenced content -->
  <xsl:template match="XMLElement[ Story/@Self = @XMLContent ]" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- root node -->
  <xsl:template match="XMLElement[ancestor::XmlStory  and  @XMLContent != '']" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates select="//Story[ @Self eq current()/@XMLContent ]" mode="#current"/>
  </xsl:template>
  <xsl:template match="Content[ ancestor::XmlStory ]" mode="idml2xml:ExtractTagging"/>
  
  <xsl:template match="XMLAttribute | Contents[ancestor::MetadataPacketPreference]" mode="idml2xml:ExtractTagging"/>
  
  <xsl:template match="Br | idml2xml:Br" mode="idml2xml:ExtractTagging">
    <idml2xml:parsep/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="*[local-name() eq 'Br'][preceding-sibling::ParagraphStyleRange and following-sibling::ParagraphStyleRange]" mode="idml2xml:ExtractTagging" />

  <xsl:template match="	TextFrame |
		       Story |
		       XmlStory | 
		       ParagraphStyleRange |
		       CharacterStyleRange |
		       Table | Row | Cell[node()]
		       "
		mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!--<xsl:template match="Column" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>-->

  <xsl:template match="ParagraphStyleRange[@AppliedParagraphStyle eq 'ParagraphStyle/Rectangle']" mode="idml2xml:ExtractTagging">
    <idml2xml:genPara>
      <xsl:attribute name="AppliedParagraphStyle" select="idml2xml:RemoveTypeFromStyleName(@AppliedParagraphStyle)" />
      <xsl:attribute name="idml2xml:reason" select="'rec1'" />
      <xsl:apply-templates mode="#current"/>
    </idml2xml:genPara>
  </xsl:template>

  <xsl:template match="Cell[not(node())]" mode="idml2xml:ExtractTagging">
    <idml2xml:genPara>
      <xsl:apply-templates select="." mode="idml2xml:ExtractAttributes"/>
    </idml2xml:genPara>
  </xsl:template>

  <xsl:template match="Content" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>



  <!--  *
        * handle shape elements, e.g. Rectangle, GraphicLine, Oval, Polygon, MultiStateObject
        * -->
  <xsl:template match="*[name() = $idml2xml:shape-element-names]" mode="idml2xml:ExtractTagging">
    <xsl:copy>
      <!--  *  
            * in case of embedded images: set @idml2xml:rectangle-embedded-source to true  
            * -->
      <xsl:attribute name="idml2xml:rectangle-embedded-source" 
         select="if(Image/Link/@StoredState eq 'Embedded') then 'true' else 'false'"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <!--  *
            * retain the Contents element or get 0KB big images
            * -->
      <xsl:copy-of select="Image/Properties/Contents"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[name() = $idml2xml:shape-element-names]
                        [*[name() = $idml2xml:shape-element-names]]
                        [every $name in */name() 
                         satisfies ($name = ($idml2xml:shape-element-names, 
                                             'Properties',
                                             'AnchoredObjectSetting',
                                             'TextWrapPreference',
                                             'InCopyExportOption',
                                             'FrameFittingOption'))]" 
                mode="idml2xml:ExtractTagging" priority="3">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="*[name() = $idml2xml:shape-element-names]
                        [not(exists(XMLElement) or exists(EPS) or exists(PDF) or exists(Image) or exists(WMF))]
                        [empty(descendant::Link/@LinkResourceURI) or count(descendant::Link/@LinkResourceURI) gt 1]
                        [empty(TextFrame | Group)]" mode="idml2xml:ExtractTagging" priority="3">
    <xsl:if test="@ContentType ne 'Unassigned'">
      <xsl:message select="concat('IDML2XML warning in ExtractTagging: ', name(), ' ', @Self, ' with unknown xml structure.')" />
    </xsl:if>
  </xsl:template>
  
  <!-- Shouldn't happen if paragraph tagging and styling are coherent -->
	<xsl:template match="ParagraphStyleRange[
                         some $pstyle in (
                           .//XMLElement[
                             .//*[self::Content or self::Br][idml2xml:same-scope(., current())]
                           ]/XMLAttribute[
                             @Name eq 'aid:pstyle'
                           ]/@Value 
                         ) satisfies (
                           $pstyle ne idml2xml:RemoveTypeFromStyleName(current()/@AppliedParagraphStyle)
                         )
                       ]" mode="idml2xml:ExtractTagging" priority="2">
    <idml2xml:ParagraphStyleRange>
      <xsl:attribute name="AppliedParagraphStyle" select="idml2xml:RemoveTypeFromStyleName(current()/@AppliedParagraphStyle)" />
      <xsl:attribute name="idml2xml:reason" select="'et1'" />
      <xsl:next-match />
    </idml2xml:ParagraphStyleRange>
	</xsl:template>


	<xsl:template match="ParagraphStyleRange[
                       every $c1 in (* | HyperlinkTextSource/*) satisfies $c1/self::CharacterStyleRange[
                           every $c2 in * satisfies $c2/self::Br (: includes the case 'not(*)', too! :)
                         ]
                       ]" mode="idml2xml:ExtractTagging" priority="2.5" />

	<xsl:template match="XMLElement
                         [@MarkupTag eq 'XMLTag/idml2xml%3agenSpan']
                         [
                           every $c1 in (* | HyperlinkTextSource/*) satisfies $c1/self::CharacterStyleRange[
                             every $c2 in * satisfies $c2/self::Br (: includes the case 'not(*)', too! :)
                           ]
                         ]
                       " mode="idml2xml:ExtractTagging" />

	<xsl:template match="XMLElement
                         [@MarkupTag eq 'XMLTag/idml2xml%3agenSpan']
                         [
                           every $a in XMLAttribute satisfies ($a/@Name = 'xmlns:idml2xml')
                         ]
                       " mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:variable name="idml2xml:indesign-link-name-suffix-regex" select="'_ID[0-9_]+$'" as="xs:string" />

  <xsl:key name="hyperlink-by-source-id" match="Hyperlink" use="@Source" />
  <xsl:key name="hyperlink-dest-by-self" match="HyperlinkURLDestination | HyperlinkPageDestination | ParagraphDestination | HyperlinkTextDestination" 
    use="@DestinationUniqueKey" />
  <xsl:key name="hyperlinkPageItemSource-by-sourcePageItem" match="HyperlinkPageItemSource" use="@SourcePageItem"/>
  
  <xsl:template match="*[key('hyperlinkPageItemSource-by-sourcePageItem', @Self)]" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates select="key('hyperlinkPageItemSource-by-sourcePageItem', @Self)" mode="#current">
      <xsl:with-param name="page-item" select="."/>
    </xsl:apply-templates>
  </xsl:template>
  
	<xsl:template match="HyperlinkTextSource[@Hidden eq 'true'] | CrossReferenceSource[@Hidden eq 'true']" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="HyperlinkTextSource | CrossReferenceSource | HyperlinkPageItemSource" mode="idml2xml:ExtractTagging">
    <xsl:param name="page-item" as="element(*)?"/><!-- only for HyperlinkPageItemSource -->
    <xsl:variable name="hyperlink" select="key('hyperlink-by-source-id', @Self)" as="element(Hyperlink)?" />
	  <xsl:variable name="destination" select="$hyperlink/Properties/Destination" as="element(Destination)?" />
	  <xsl:choose>
      <xsl:when test="empty($hyperlink)">
        <xsl:message>warning: idml2xml ExtractTagging.xsl template match="HyperlinkTextSource | CrossReferenceSource":
        No Hyperlink element found for source with @Self <xsl:value-of select="@Self"/>
        </xsl:message>
        <xsl:apply-templates mode="#current" />
      </xsl:when>
	    <xsl:when test="empty($destination)">
	      <xsl:message>warning: idml2xml ExtractTagging.xsl template match="HyperlinkTextSource | CrossReferenceSource":
	        No Destination element found for source with @Self <xsl:value-of select="@Self"/>, Hyperlink with @Self <xsl:value-of select="$hyperlink/@Self"/>
	      </xsl:message>
	      <xsl:apply-templates mode="#current" />
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:if test="count($destination) gt 1">
	        <xsl:message>warning: idml2xml ExtractTagging.xsl template match="HyperlinkTextSource | CrossReferenceSource":
	          Multiple Destination elements found for source with @Self <xsl:value-of select="@Self"/>, Hyperlink with @Self <xsl:value-of select="$hyperlink/@Self"/>.
	          Processing only the first one.
	        </xsl:message>
	      </xsl:if>
	      <xsl:apply-templates select="$destination[1]" mode="idml2xml:ExtractTagging_Linking">
          <xsl:with-param name="document-context" select="($page-item, .)[1]"/>
        </xsl:apply-templates>
      </xsl:otherwise>
	  </xsl:choose>
	</xsl:template>
  
  <!-- Destinations in the same document: -->
  <xsl:template match="Destination[@type eq 'object']" mode="idml2xml:ExtractTagging_Linking">
    <xsl:param name="document-context" as="element(*)"/>
    <xsl:variable name="target-element-name" select="substring-before(., '/')" as="xs:string"/>
    <xsl:variable name="dest" select="key('hyperlink-dest-by-self', ../../@DestinationUniqueKey)" as="element(*)*"/>
    <xsl:choose>
      <xsl:when
        test="$target-element-name = ('ParagraphDestination', 'HyperlinkTextDestination')">
        <idml2xml:link linkend="{idml2xml:escape-id(.)}" remap="{$target-element-name}">
          <xsl:call-template name="idml2xml:extract-tagging_render-link-document-context">
            <xsl:with-param name="document-context" select="$document-context"/>
          </xsl:call-template>
        </idml2xml:link>
      </xsl:when>
      <xsl:when test="$target-element-name eq 'HyperlinkPageDestination'">
        <!-- is $document-context/@Name intended? -->
        <idml2xml:link linkend="id_{$document-context/@Name}" remap="{$target-element-name}">
          <xsl:call-template name="idml2xml:extract-tagging_render-link-document-context">
            <xsl:with-param name="document-context" select="$document-context"/>
          </xsl:call-template>
        </idml2xml:link>
      </xsl:when>
      <xsl:when test="$target-element-name eq 'HyperlinkURLDestination'">
        <idml2xml:link xlink:href="{normalize-space($dest[1]/@DestinationURL)}">
          <!-- only use first item, sometimes the link url appears twice, MK 2013-04-23 -->
          <xsl:call-template name="idml2xml:extract-tagging_render-link-document-context">
            <xsl:with-param name="document-context" select="$document-context"/>
          </xsl:call-template>
        </idml2xml:link>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$document-context/self::HyperlinkTextSource or $document-context/self::CrossReferenceSource">
            <xsl:apply-templates select="$document-context/node()" mode="idml2xml:ExtractTagging"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Typically a Rectangle: -->
            <xsl:for-each select="$document-context">
              <xsl:copy>
                <xsl:apply-templates select="@*, node()" mode="idml2xml:ExtractTagging"/>
              </xsl:copy>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:message>warning: idml2xml ExtractTagging.xsl template match="HyperlinkTextSource | CrossReferenceSource| HyperlinkPageItemSource": Don't know how to handle <xsl:value-of
            select="."/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="idml2xml:extract-tagging_render-link-document-context">
    <xsl:param name="document-context" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$document-context/self::HyperlinkTextSource or $document-context/self::CrossReferenceSource">
        <xsl:apply-templates select="$document-context/(@srcpath, node())" mode="idml2xml:ExtractTagging"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Typically a Rectangle: -->
        <xsl:for-each select="$document-context">
          <xsl:copy>
            <xsl:apply-templates select="@*, node()" mode="idml2xml:ExtractTagging"/>
          </xsl:copy>
        </xsl:for-each>    
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Destination is in an external document -->
  <xsl:template match="Destination[@type eq 'list']" mode="idml2xml:ExtractTagging_Linking">
    <xsl:param name="document-context" as="element(*)"/>
    <xsl:variable name="name"
      select="replace(ancestor::Hyperlink/@Name, $idml2xml:indesign-link-name-suffix-regex, '')"
      as="xs:string"/>
    <xsl:variable name="file-uri" select="  concat(
                                              'file:',
                                              if (matches(ListItem[1], '^[a-z]:[\\/]', 'i')) then '/' else '',
                                              replace(
                                                replace(
                                                  encode-for-uri(
                                                    replace(ListItem[1], '\\', '/')
                                                  ),
                                                  '%3A',
                                                  ':'
                                                ),
                                                '%2F',
                                                '/'
                                              )
                                            )" as="xs:string"/>
    <idml2xml:link xlink:href="{$file-uri}?name={$name}" remap="ExternalHyperlinkTextDestination">
      <xsl:apply-templates select="$document-context/(@srcpath, node())" mode="idml2xml:ExtractTagging"/>
    </idml2xml:link>
  </xsl:template>

  <!-- Destination is in a clipboard scrap -->
  <xsl:template match="Destination[@type eq 'list'][matches(ListItem[1], '^InDesign ClipboardScrap')]" 
    priority="2" mode="idml2xml:ExtractTagging_Linking">
    <xsl:param name="document-context" as="element(*)"/>
    <xsl:message>Hyperlink <xsl:value-of select="ancestor::Hyperlink/@Self"/> does not point to a destination in the document. (Source text: <xsl:value-of select="$document-context"/>)</xsl:message>  
    <idml2xml:link xlink:href="" remap="InDesignClipboardScrap">
      <xsl:apply-templates select="$document-context/(@srcpath, node())" mode="idml2xml:ExtractTagging"/>
    </idml2xml:link>
  </xsl:template>
  

  <xsl:template match="ParagraphDestination | HyperlinkTextDestination" mode="idml2xml:ExtractTagging">
    <idml2xml:genAnchor xml:id="{idml2xml:escape-id(@Self)}" remap="{local-name()}" 
      annotations="{replace(@Name, '^.+?/', '')}"/>
  </xsl:template>

  <xsl:template match="TextVariableInstance" mode="idml2xml:ExtractTagging">
    <xsl:value-of select="@ResultText"/>
  </xsl:template>



	<!-- delete the following elements and their children-->
	<xsl:template match=" Properties[not(parent::*[name() = $idml2xml:shape-element-names])] |
                        StoryPreference |
												InCopyExportOption"
		mode="idml2xml:ExtractTagging"/>
	
  <xsl:template match="text()" mode="idml2xml:ExtractTagging">
    <xsl:analyze-string select="." regex="&#9;">
      <xsl:matching-substring>
        <idml2xml:tab>
          <xsl:text>&#9;</xsl:text>
        </idml2xml:tab>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

	<!-- sometimes there are processing-instructions, e.g. <?ACE 8?> -->
	<xsl:template match="processing-instruction()[not(name() = 'xml-model')]" mode="idml2xml:ExtractTagging" priority="0.25">
    <xsl:message>PI
		<xsl:copy-of select="."/>
    </xsl:message>
		<xsl:copy-of select="."/>
	</xsl:template>

  <xsl:template match="processing-instruction()[name() eq 'ACE'][. eq '3']" mode="idml2xml:ExtractTagging">
    <idml2xml:tab role="end-nested-style" />
  </xsl:template>

  <xsl:template match="processing-instruction()[name() eq 'ACE'][. eq '4']" mode="idml2xml:ExtractTagging">
    <idml2xml:tab role="footnotemarker" />
  </xsl:template>

  <xsl:template match="processing-instruction()[name() eq 'ACE'][. eq '7']" mode="idml2xml:ExtractTagging">
    <idml2xml:tab role="indent-to-here" />
  </xsl:template>

  <xsl:template match="processing-instruction()[name() eq 'ACE'][. eq '8']" mode="idml2xml:ExtractTagging">
    <idml2xml:tab role="right" />
  </xsl:template>

  <xsl:template match="processing-instruction()[name() eq 'ACE'][. eq '18']" mode="idml2xml:ExtractTagging">
    <idml2xml:control role="hub:page-number" />
  </xsl:template>

</xsl:stylesheet>
