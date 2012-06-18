<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
  xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
  xmlns:aid		= "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5	= "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg	=	"http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml	= "http://www.le-tex.de/namespace/idml2xml"
  xmlns:xlink	= "http://www.w3.org/1999/xlink"
  exclude-result-prefixes="aid5 aid xs"
>

  <!--== mode: idml2xml:ExtractTagging ==-->
	
  <xsl:template match="Document" mode="idml2xml:ExtractTagging">
    <idml2xml:doc>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:copy-of select="(idPkg:Graphic, idPkg:Styles, idml2xml:hyper, idml2xml:lang)" />
      <xsl:apply-templates select="XmlStory" mode="#current"/>
      <xsl:variable name="processed-stories" as="xs:string*">
        <xsl:apply-templates select="XmlStory" mode="idml2xml:ExtractTagging-gather-IDs"/>
      </xsl:variable>
      <xsl:apply-templates select="TextFrame/Story[not(@Self = distinct-values($processed-stories))] " mode="#current"/>
      <xsl:apply-templates select="Rectangle" mode="#current"/>
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
      <xsl:apply-templates select="(XMLAttribute, Properties, Table)" mode="idml2xml:ExtractAttributes"/>
      <xsl:if test="not(XMLAttribute[@Name eq 'aid:cstyle'])">
        <xsl:apply-templates select="(ancestor::ParagraphStyleRange, ../ancestor::XMLElement)[last()]" mode="idml2xml:ExtractAttributes"/>
      </xsl:if>
      <xsl:if test="not(XMLAttribute[@Name eq 'aid:pstyle'])">
        <xsl:apply-templates select="ancestor::CharacterStyleRange[1]" mode="idml2xml:ExtractAttributes"/>
      </xsl:if>
      <!-- ancestor::XMLElement[1] is here for the following reason:
           If Cell was preceded by XMLElement when looking upwards the ancestor axis, do nothing. -->
      <xsl:apply-templates select="(ancestor::Cell[1] union ancestor::XMLElement[1])[last()]" mode="idml2xml:ExtractAttributes"/>


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

  <xsl:template match="CharacterStyleRange[@AppliedCharacterStyle eq 'CharacterStyle/$ID/[No character style]']" mode="idml2xml:ExtractAttributes" />

  <xsl:template match="@AppliedParagraphStyle | @AppliedCharacterStyle" mode="idml2xml:ExtractAttributes">
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
    <xsl:attribute name="aid:tcols" select="count( Column )"/>
    <xsl:attribute name="aid:trows" select="count( Row )"/>
    <xsl:attribute name="aid5:tablestyle" select="idml2xml:RemoveTypeFromStyleName(@AppliedTableStyle)"/>
    <xsl:copy-of select="ancestor::Story[1]/parent::TextFrame/@idml2xml:AppliedObjectStyle" />
  </xsl:template>

  <xsl:template match="Cell" mode="idml2xml:ExtractAttributes">
    <xsl:attribute name="aid:table" select="'cell'"/>
    <xsl:attribute name="aid:ccols" select="@ColumnSpan"/>
    <xsl:attribute name="aid:crows" select="@RowSpan"/>
    <xsl:attribute name="aid:ccolwidth" 
      select="preceding::Column[ @Name eq tokenize( current()/@Name, ':' )[1] ][1]/@SingleColumnWidth"/>
    <xsl:attribute name="aid5:cellstyle" select="idml2xml:RemoveTypeFromStyleName(@AppliedCellStyle)"/>
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
    <idml2xml:newline/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>

  <xsl:template match="	TextFrame |
		       Story |
		       XmlStory | 
		       ParagraphStyleRange |
		       CharacterStyleRange |
		       Table | Row | Column | Cell[node()]
		       "
		mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="Cell[not(node())]" mode="idml2xml:ExtractTagging">
    <idml2xml:genPara>
      <xsl:apply-templates select="." mode="idml2xml:ExtractAttributes"/>
    </idml2xml:genPara>
  </xsl:template>

  <xsl:template match="Content" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="Rectangle[exists(EPS) or exists(PDF) or exists(Image)][empty(descendant::Link/@LinkResourceURI)]" mode="idml2xml:ExtractTagging">
    <xsl:copy>
      <xsl:attribute name="idml2xml:rectangle-embedded-source" select="'true'"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="Rectangle[not(exists(EPS) or exists(PDF) or exists(Image))][not(empty(descendant::Link/@LinkResourceURI))]" mode="idml2xml:ExtractTagging">
    <xsl:copy>
      <xsl:apply-templates select="@*|descendant::Link/@LinkResourceURI" mode="#current"/>
    </xsl:copy>
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


  <xsl:key name="hyperlink-by-source-id" match="Hyperlink" use="@Source" />
  <xsl:key name="hyperlink-dest-by-self" match="HyperlinkURLDestination | HyperlinkPageDestination | ParagraphDestination | HyperlinkTextDestination" use="@Self" />

	<xsl:template match="HyperlinkTextSource[@Hidden eq 'true'] | CrossReferenceSource[@Hidden eq 'true']" mode="idml2xml:ExtractTagging">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

	<xsl:template match="HyperlinkTextSource | CrossReferenceSource" mode="idml2xml:ExtractTagging">
    <xsl:variable name="hyperlink" select="key('hyperlink-by-source-id', @Self)" as="element(Hyperlink)?" />
    <xsl:choose>
      <xsl:when test="empty($hyperlink)">
        <xsl:message>WRN: idml2xml ExtractTagging.xsl template match="HyperlinkTextSource | CrossReferenceSource":
        No Hyperlink element found for source with @Self <xsl:value-of select="@Self"/>
        </xsl:message>
        <xsl:apply-templates mode="#current" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="dest-id" select="$hyperlink/Properties/Destination" as="xs:string" />
        <xsl:variable name="target-element-name" select="substring-before($dest-id, '/')" as="xs:string" />
        <xsl:variable name="dest" select="key('hyperlink-dest-by-self', $dest-id)" as="element(*)?" />
        <xsl:choose>
          <xsl:when test="empty($dest)">
            <xsl:message>WRN: idml2xml ExtractTagging.xsl template match="HyperlinkTextSource | CrossReferenceSource":
            No target found for hyperlink <xsl:value-of select="$dest-id"/>
            </xsl:message>
            <xsl:apply-templates mode="#current" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="$target-element-name = ('ParagraphDestination', 'HyperlinkTextDestination')">
                <idml2xml:link linkend="{idml2xml:escape-id($dest-id)}" remap="{$target-element-name}">
                  <xsl:apply-templates mode="#current" />
                </idml2xml:link>
              </xsl:when>
              <xsl:when test="$target-element-name eq 'HyperlinkPageDestination'">
                <idml2xml:link linkend="id_{@Name}"  remap="{$target-element-name}">
                  <xsl:apply-templates mode="#current" />
                </idml2xml:link>
              </xsl:when>
              <xsl:when test="$target-element-name eq 'HyperlinkURLDestination'">
                <idml2xml:link xlink:href="{$dest/@DestinationURL}">
                  <xsl:apply-templates mode="#current" />
                </idml2xml:link>
              </xsl:when>
              <xsl:otherwise>
                <xsl:message>WRN: idml2xml ExtractTagging.xsl template match="HyperlinkTextSource | CrossReferenceSource":
                Don't know how to handle <xsl:value-of select="$target-element-name"/> 
                </xsl:message>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="ParagraphDestination | HyperlinkTextDestination" mode="idml2xml:ExtractTagging">
    <idml2xml:genAnchor xml:id="{idml2xml:escape-id(@Self)}" remap="{local-name()}"/>
  </xsl:template>

  <xsl:template match="TextVariableInstance" mode="idml2xml:ExtractTagging">
    <xsl:value-of select="@ResultText"/>
  </xsl:template>



	<!-- delete the following elements and their children-->
	<xsl:template match=" Properties |
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
	<xsl:template match="processing-instruction()" mode="idml2xml:ExtractTagging">
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
    <idml2xml:tab role="right-indent" />
  </xsl:template>

  <xsl:template match="processing-instruction()[name() eq 'ACE'][. eq '18']" mode="idml2xml:ExtractTagging">
    <idml2xml:control role="page-number" />
  </xsl:template>

</xsl:stylesheet>