<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
    exclude-result-prefixes = "idPkg aid5 aid xs"
>
  <!--== KEYs ==-->
  <xsl:key name="story" match="Story" use="@Self"/>

  <!--== mode: Document ==-->
  <xsl:template match="
                        idPkg:Fonts |
                        idPkg:Graphic |
                        idPkg:Mapping |
                        idPkg:MasterSpread | 
                        idPkg:Preferences |
                        idPkg:Spread | 
                        idPkg:Story |
                        idPkg:Styles |
                        idPkg:Tags" 
                mode="idml2xml:Document">
    <xsl:apply-templates select="document(@src)" mode="#current"/>
  </xsl:template>

  <!-- unplaced XML: -->
  <xsl:template match=" idPkg:BackingStory" mode="idml2xml:Document" />
    
  <xsl:template match="/processing-instruction()" mode="idml2xml:Document" />

  <xsl:template match="/" mode="idml2xml:Document">
    <xsl:document>
      <xsl:apply-templates mode="#current" />
    </xsl:document>
  </xsl:template>

  <xsl:template match="/*" mode="idml2xml:Document">
    <xsl:copy>
      <xsl:namespace name="idml2xml" select="'http://www.le-tex.de/namespace/idml2xml'" />
      <xsl:attribute name="xml:base" select="base-uri(.)" />
      <xsl:copy-of select="@*, /processing-instruction()"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Cell | CharacterStyleRange | HyperlinkTextSource | Footnote
                       | ParagraphStyleRange | Table | XMLElement | Image | EPS | PDF"
    mode="idml2xml:Document">
    <xsl:copy>
      <xsl:if test="$srcpaths = 'yes'">
        <xsl:attribute name="srcpath" select="idml2xml:srcpath(.)" />
      </xsl:if>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:function name="idml2xml:srcpath" as="xs:string">
    <xsl:param name="elt" as="element(*)?" />
    <xsl:sequence select="string-join(
                            (
                              if ($elt/.. instance of element(*)) then idml2xml:srcpath($elt/..) else concat(base-uri($elt), '?xpath='),
                              '/',
                              name($elt),
                              '[',
                              xs:string(index-of(for $s in $elt/../*[name() = name($elt)] return generate-id($s), generate-id($elt))),
                              ']'
                            ),
                            ''
                          )"/>
  </xsl:function>

  <idml2xml:default-namespaces>
    <XMLAttribute Name="xmlns:idml2xml" Value="http://www.le-tex.de/namespace/idml2xml"/>
    <XMLAttribute Name="xmlns:aid" Value="http://ns.adobe.com/AdobeInDesign/4.0/"/>
    <XMLAttribute Name="xmlns:aid5" Value="http://ns.adobe.com/AdobeInDesign/5.0/"/>
    <XMLAttribute Name="xmlns:ac" Value="http://ns.acolada.de/InDesignPlugIn/1.0/"/>
  </idml2xml:default-namespaces>

  <!--== mode: DocumentStoriesSorted ==-->

  <!-- root template -->
  <xsl:template match="/" mode="idml2xml:DocumentStoriesSorted">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="/Document" mode="idml2xml:DocumentStoriesSorted">

    <!-- debug messages: list informations about spread childs -->
    <!--
    <xsl:message select="'PageHeight:', xs:string(//@PageHeight)"/>
    <xsl:message select="'PageWidth:', xs:string(//@PageWidth)"/>
    <xsl:for-each select="//Spread">
      <xsl:message select="' === SPREAD', xs:string(@Self), xs:string(@ItemTransform), @BindingLocation"/>
      <xsl:for-each select=".//TextFrame union .//Group union .//Rectangle">
        <xsl:message select="' ...', local-name(.), xs:string(@Self), xs:string(@ItemTransform), string-join(PathPointType/@*,'#'), 'TEXT:', substring(string-join($idml2xml:Document//Story[@Self eq current()/@ParentStory]//Content/text(),''), 0, 42)"/>    
      </xsl:for-each>
    </xsl:for-each>
    -->

    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current" />
      <xsl:attribute name="TOCStyle_Title" select="//TOCStyle[@Title ne ''][1]/@Title"/>
      <idml2xml:namespaces>
        <xsl:for-each-group
          select="//XMLAttribute[ @Name[ matches( ., '^xmlns:' ) ] ] 
                  union document('')/*/idml2xml:default-namespaces/XMLAttribute" 
          group-by="@Value">
          <ns short="{substring-after( @Name, ':' )}" space="{@Value}" />
        </xsl:for-each-group>
      </idml2xml:namespaces>
      <xsl:copy-of select="idPkg:Graphic" />
      <xsl:copy-of select="idPkg:Styles" />
      <idml2xml:hyper>
        <xsl:copy-of select="HyperlinkPageDestination | HyperlinkURLDestination | Hyperlink" />
      </idml2xml:hyper>
      <idml2xml:lang>
        <xsl:copy-of select="Language" />
      </idml2xml:lang>
      <idml2xml:cond>
        <xsl:copy-of select="Condition" />
      </idml2xml:cond>
      <xsl:for-each-group select="  idPkg:Spread/Spread/TextFrame[$output-items-not-on-workspace = ('yes','1','true') or idml2xml:item-is-on-workspace(.)]
                                  | idPkg:Spread/Spread/Group[TextFrame][$output-items-not-on-workspace = ('yes','1','true') or idml2xml:item-is-on-workspace(.)]" 
        group-by="(@ParentStory, TextFrame/@ParentStory)">
        <xsl:apply-templates
          select="(current-group()/(self::TextFrame, self::Group/TextFrame)[@ParentStory eq current-grouping-key()])[1]"
          mode="idml2xml:DocumentResolveTextFrames" />
      </xsl:for-each-group>
      <!-- apply content not in @select-term of preceding for-each-group -->
      <xsl:apply-templates mode="idml2xml:DocumentResolveTextFrames"
        select="//Spread/TextFrame/Group,
                //Spread/Group[TextFrame]/Group,
                //Spread//Group[
                  not(
                    ancestor::TextFrame[parent::Spread] or 
                    ancestor-or-self::Group[TextFrame][parent::Spread]
                  ) and (: do not include sub Groups in these Groups :)
                  not(
                    ancestor::Group[
                      not(
                        ancestor::TextFrame[parent::Spread] or 
                        ancestor-or-self::Group[TextFrame][parent::Spread]
                      )
                    ]
                  )
                ]
                , 
                //Spread/*[name() = $idml2xml:shape-element-names],
                //XmlStory" />
    </xsl:copy>
  </xsl:template>

  <xsl:variable name="idml2xml:content-group-children" as="xs:string+"
    select="('TextFrame', 'AnchoredObjectSetting', 'TextWrapPreference', 'ObjectExportOption', $idml2xml:shape-element-names)"/>
  
  <!-- A Group that is in a Story (rather than in a Spread -->
  <xsl:template match="Group[not(ancestor::Spread)]
    [every $c in * satisfies ($c/name() = $idml2xml:content-group-children)]"
    mode="idml2xml:DocumentResolveTextFrames" priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="TextFrame | *[name() = $idml2xml:shape-element-names]" 
        group-adjacent="self::TextFrame/@ParentStory, .[not(self::TextFrame)]/@Self">
        <xsl:apply-templates select="." mode="#current" />
      </xsl:for-each-group>
    </xsl:copy>
    
  </xsl:template>

  <xsl:template match="Group[not(ancestor::Spread)]
    [not(every $c in * satisfies ($c/name() = content-group-children))]"
    mode="idml2xml:DocumentResolveTextFrames" >
    <xsl:comment>HANDLE ME! (I'm in Document.xsl)</xsl:comment>
    <xsl:message>HANDLE ME! (I'm in Document.xsl)</xsl:message>
    <xsl:next-match/>    
  </xsl:template>
  

  <xsl:template match="TextFrame[
                         parent::Spread or 
                         parent::Group[parent::Spread]
                       ]" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy>
      <xsl:apply-templates select="@* | *" mode="#current" />
      <xsl:apply-templates select="key( 'story', current()/@ParentStory )" mode="#current">
        <xsl:with-param name="is-a-grouped-spread-textframe" select="true()" tunnel="yes"/>
        <xsl:with-param name="textframe" select="." tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="TextFrame[
                         not(
                           parent::Spread or 
                           parent::Group[parent::Spread]
                         )
                       ]" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy>
      <xsl:apply-templates select="@* | *" mode="#current" />
      <xsl:apply-templates select="key( 'story', current()/@ParentStory )" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Story" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:param name="textframe" as="node()?" tunnel="yes"/>
    <xsl:param name="is-a-grouped-spread-textframe" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$is-a-grouped-spread-textframe and
                      $textframe/parent::Group and 
                      (
                        $textframe/preceding-sibling::*[name() = $idml2xml:shape-element-names] or 
                        $textframe/following-sibling::*[name() = $idml2xml:shape-element-names]
                      )">
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current" />
          <Group>
            <xsl:choose>
              <xsl:when test="$textframe/preceding-sibling::TextFrame">
                <xsl:variable name="last-preceding-textframe" as="element(TextFrame)"
                  select="$textframe/preceding-sibling::TextFrame[1]"/>
                <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Rectangle">
                  <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]">
                    <xsl:apply-templates select="$textframe/preceding-sibling::*[name() = $idml2xml:shape-element-names][ . &gt;&gt; $last-preceding-textframe ]" mode="#current"/>
                  </CharacterStyleRange>
                  <Br/>
                </ParagraphStyleRange>
              </xsl:when>
              <xsl:otherwise>
                <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Rectangle">
                  <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]">
                    <xsl:apply-templates select="$textframe/preceding-sibling::*[name() = $idml2xml:shape-element-names]" mode="#current"/>
                  </CharacterStyleRange>
                  <Br/>
                </ParagraphStyleRange>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="node()" mode="#current" />
            <xsl:if test="not($textframe/following-sibling::TextFrame)">
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Rectangle">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]">        
                  <xsl:apply-templates select="$textframe/following-sibling::*[name() = $idml2xml:shape-element-names]" mode="#current"/>
                </CharacterStyleRange>
                <Br/>
              </ParagraphStyleRange>
            </xsl:if>
          </Group>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="TextFrame/*" mode="idml2xml:DocumentResolveTextFrames" />
  <xsl:template match="TextFrame/@*" mode="idml2xml:DocumentResolveTextFrames" priority="0" />
  <xsl:template match="TextFrame/@AppliedObjectStyle" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:attribute name="idml2xml:{local-name()}" select="replace( idml2xml:substr( 'a', ., 'ObjectStyle/' ), '%3a', ':' )" />
  </xsl:template>

  <!-- remove items not on workspace other than Spread/Group[TextFrame], Spread/TextFrame  -->
  <xsl:template 
    match="*[
              name() = $idml2xml:shape-element-names 
              or Group[not(TextFrame)]
            ]
            [
             (
               ancestor::Spread 
               and
               not(idml2xml:item-is-on-workspace(.))
             ) 
             or $output-items-not-on-workspace = ('yes','1','true')
           ]" 
    mode="idml2xml:DocumentResolveTextFrames" />

  <!-- anchored image: need an extra paragraph -->
  <xsl:template mode="idml2xml:DocumentResolveTextFrames"
    match="*[name() = $idml2xml:shape-element-names][not(ancestor::Spread)][AnchoredObjectSetting and not(AnchoredObjectSetting/@AnchoredPosition)]" priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
    <Br reason="Rectangle_anchored" />
  </xsl:template>

  <!-- -->
  <xsl:template mode="idml2xml:DocumentResolveTextFrames"
    match="Group[not(ancestor::Spread)]/*[name() = $idml2xml:shape-element-names]" >
    <xsl:copy>
      <xsl:attribute name="idml2xml:keep-object" select="'true'"/>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>
  
  <!-- element Change: textual changes -->

  <xsl:template 
    match="Change[ not($output-deleted-text = ('yes','1','true')) and @ChangeType eq 'DeletedText']" 
    mode="idml2xml:DocumentResolveTextFrames" />

  <xsl:template 
    match="Change[ @ChangeType = ('InsertedText', 'MovedText') ]" 
    mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- remove (binary) metadata to reduce debugging file size: can be resolved from variable Document -->
  <xsl:template match="MetadataPacketPreference" mode="idml2xml:DocumentResolveTextFrames" />

  <!-- Remove new Story XMLElements, see also idml-specification.pdf page 235-236 -->
  <xsl:template match="XMLElement[ idml2xml:substr( 'a', @MarkupTag, 'XMLTag/' ) = /Document/idPkg:Preferences/XMLPreference/@DefaultStoryTagName  and  @XMLContent ]" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- Remove existing tagging (recommended when generating Hub XML) -->
  <xsl:template match="XMLElement[$discard-tagging = 'yes']" mode="idml2xml:DocumentResolveTextFrames" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="XMLAttribute[$discard-tagging = 'yes']" mode="idml2xml:DocumentResolveTextFrames"/>

  <xsl:template match="XMLInstruction[$discard-tagging = 'yes']" mode="idml2xml:DocumentResolveTextFrames"/>
  
</xsl:stylesheet>
