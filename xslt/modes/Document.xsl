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

  <xsl:template match="@CrossReferenceType[. eq 'CustomCrossReferenceBefore']" mode="idml2xml:Document">
    <xsl:attribute name="{local-name()}">
      <xsl:choose>
        <xsl:when test="matches(parent::*/@CustomTypeString, '^(&#xfeff;)?(siehe[\s]auch|see[\s]also|(s\.|siehe\s)a\.)', 'i')">SeeAlso</xsl:when>
        <xsl:when test="matches(parent::*/@CustomTypeString, '^(&#xfeff;)?(siehe|see|s\.)', 'i')">See</xsl:when>
        <xsl:when test="matches(parent::*/@ReferencedTopic, 'Topicn(siehe[\s]auch|see[\s]also|(s\.|siehe\s)a\.)\s', 'i')">SeeAlso</xsl:when>
        <xsl:when test="matches(parent::*/@ReferencedTopic, 'Topicn(siehe|see|s\.)\s', 'i')">See</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="." />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="CrossReference[@CrossReferenceType[. eq 'CustomCrossReferenceBefore']]/@ReferencedTopic[matches(., 'Topicn(siehe|see|s\.)\s', 'i')]" mode="idml2xml:Document">
    <xsl:attribute name="{local-name()}" select="replace(., '([Ss]iehe([\s]auch)?|[Ss]ee([\s]also)?|[Ss]\.(a\.)?)\s', '')" />
  </xsl:template>


  <!--== mode: DocumentStoriesSorted ==-->

  <!-- root template -->
  <xsl:template match="/" mode="idml2xml:DocumentStoriesSorted">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="/Document" mode="idml2xml:DocumentStoriesSorted">
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
      <idml2xml:index>
        <xsl:copy-of select="Index" />
      </idml2xml:index>
      <!-- The following instruction will only work as expected if $output-items-not-on-workspace is false so that the return
        value of idml2xml:item-is-on-workspace() becomes significant. This function will return false() for TextFrames that
        don’t have a Spread ancestor. TextFrames that are anchored are contained in a story and therefore don’t have a Spread 
        ancestor. 
        In addition, if $use-StoryID-conditional-text-for-anchoring is true, processing of TextFrames will be suppressed if
        they contain a Story whose StoryID conditional text matches a StoryRef somewhere else. The first TextFrame that contains
        such a StoryID will be processed in lieu of any StoryRef conditional text with the same content. -->
      <!--<xsl:apply-templates 
        select=".//TextFrame[@PreviousTextFrame eq 'n']
                            [$output-items-not-on-workspace = ('yes','1','true') or idml2xml:item-is-on-workspace(.)]
                            [not($use-StoryID-conditional-text-for-anchoring = ('yes','1','true') and idml2xml:conditional-text-anchored(.))],
                //Spread/*[name() = $idml2xml:shape-element-names],
                //XmlStory" 
        mode="idml2xml:DocumentResolveTextFrames"/>-->
      <xsl:apply-templates 
        select="idPkg:Spread/Spread/(
                                         TextFrame[idml2xml:is-story-origin(.)]
                                       | Group[.//(TextFrame[idml2xml:is-story-origin(.)] | *[name() = $idml2xml:shape-element-names])]
                                       | *[name() = $idml2xml:shape-element-names]
                                    ),
                //XmlStory" 
        mode="idml2xml:DocumentResolveTextFrames"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Group/TextWrapPreference" mode="idml2xml:DocumentResolveTextFrames"/>

  <xsl:function name="idml2xml:is-story-origin" as="xs:boolean">
    <xsl:param name="frame" as="element(TextFrame)"/>
    <xsl:sequence select="exists(
                            $frame[@PreviousTextFrame eq 'n']
                                  [$output-items-not-on-workspace = ('yes','1','true') or idml2xml:item-is-on-workspace(.)]
                                  [not($use-StoryID-conditional-text-for-anchoring = ('yes','1','true') and idml2xml:conditional-text-anchored(.))]
                          )"/>
  </xsl:function>

  <!-- there may be multiple StoryRefs in a Story, but only one StoryID (if there were multiple StoryIDs,
       they’d be concatenated) -->
  <xsl:key name="referencing-Story-by-StoryID" match="Story[.//*[@AppliedConditions eq 'Condition/StoryRef']]"
    use="for $r in .//*[@AppliedConditions eq 'Condition/StoryRef'] return idml2xml:text-content($r)"/>
  
  <xsl:key name="Story-by-StoryID" match="Story[.//@AppliedConditions[. = 'Condition/StoryID']]" 
    use="string-join(for $e in .//*[@AppliedConditions = 'Condition/StoryID'] return idml2xml:text-content($e), '')"/>
  
  <xsl:key name="TextFrame-by-ParentStory" match="TextFrame[@PreviousTextFrame eq 'n']" use="@ParentStory"/>
  <xsl:key name="Story-by-Self" match="Story" use="@Self"/>

  <xsl:function name="idml2xml:conditional-text-anchored" as="xs:boolean">
    <xsl:param name="frame" as="element(TextFrame)"/>
    <xsl:variable name="id" as="xs:string?"  
      select="string-join( 
                            for $e in key('Story-by-Self', $frame/@ParentStory, root($frame))//*[@AppliedConditions = 'Condition/StoryID'] 
                            return idml2xml:text-content($e), 
                            '' 
                          )"/>
    <xsl:variable name="referencing-story" as="element(Story)?" select="key('referencing-Story-by-StoryID', $id, root($frame))"/>
    <xsl:sequence select="if ($id and $id != '') 
                          then exists($referencing-story) and ($referencing-story/@Self != $frame/@ParentStory) 
                          else false()"/>
  </xsl:function>

  <xsl:template match="*[@AppliedConditions eq 'Condition/StoryRef']" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="story" select="key('Story-by-StoryID', idml2xml:text-content(.))" as="element(Story)?"/>
      <xsl:choose>
        <xsl:when test="not($story/@Self)"><!-- doesn’t resolve, reproduce applied conditions and content 
          so that Schematron can report non-resolution -->
          <xsl:copy-of select="@AppliedConditions, node()"/>
        </xsl:when>
        <xsl:when test="not($story/@Self = ancestor::Story/@Self)">
          <TextFrame bla="blup">
            <xsl:apply-templates select="key('TextFrame-by-ParentStory', $story/@Self)/(@*, *)" mode="#current"/>
            <xsl:apply-templates select="$story" mode="#current"/>
          </TextFrame>
        </xsl:when>
        <!-- otherwise: the story is anchored within itself, don’t do nothing -->
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@AppliedConditions eq 'Condition/FigureRef']" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:copy-of select="(//Rectangle[ends-with(.//@LinkResourceURI, normalize-space(idml2xml:text-content(current())))])[1]"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="Rectangle[some $ref in //*[@AppliedConditions eq 'Condition/FigureRef']
                                 satisfies (ends-with(current()//@LinkResourceURI, normalize-space(idml2xml:text-content($ref))))]"
    mode="idml2xml:DocumentResolveTextFrames"/>

  <xsl:function name="idml2xml:text-content" as="xs:string?">
    <xsl:param name="elt" as="element(*)?"/>
    <xsl:sequence select="string-join($elt//Content, '')"/>
  </xsl:function>
  

  <xsl:template match="  HiddenText[.//@AppliedConditions = ('Condition/StoryRef', 'Condition/FigureRef')]
                       | HiddenText[.//@AppliedConditions = ('Condition/StoryRef', 'Condition/FigureRef')]/ParagraphStyleRange[not(@AppliedConditions)]" 
    mode="idml2xml:DocumentResolveTextFrames" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- dissolve pstyleranges in hidden text that serves a pseudo-anchoring purpose 
        and that doesn’t contain a paragraph break -->
  <xsl:template match="ParagraphStyleRange[every $br in .//Br[idml2xml:same-scope(., current())]
                                           satisfies ($br/ancestor::*/@AppliedConditions = ('Condition/StoryRef', 'Condition/FigureRef'))]
                                          [not( (ancestor::Story[1]//ParagraphStyleRange)[last()] )]" 
                mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="HiddenText[.//@AppliedConditions = 'Condition/StoryID']
                                 [exists(
                                    key(
                                      'referencing-Story-by-StoryID', 
                                      string-join(
                                        for $ht in ancestor::Story//*[@AppliedConditions = 'Condition/StoryID']
                                        return idml2xml:text-content($ht),
                                        ''
                                      )
                                    )
                                 )]" 
                mode="idml2xml:DocumentResolveTextFrames"/>

  <xsl:template match="*[@AppliedConditions eq 'Condition/StoryID']
    [exists(key('referencing-Story-by-StoryID', string-join(
                                                  for $ht in ancestor::Story//*[@AppliedConditions = 'Condition/StoryID']
                                                  return idml2xml:text-content($ht),
                                                  ''
                                                )
                                                ))]" 
                mode="idml2xml:DocumentResolveTextFrames"/>

  <xsl:template match="@AppliedConditions[. eq 'Condition/StoryRef']" mode="idml2xml:DocumentResolveTextFrames"/>

  <xsl:variable name="idml2xml:content-group-children" as="xs:string+"
    select="('TextFrame', 'AnchoredObjectSetting', 'TextWrapPreference', 'ObjectExportOption', $idml2xml:shape-element-names)"/>
  
  <!-- A Group that is in a Story (rather than in a Spread -->
  <xsl:template match="Group[not(ancestor::Spread)]
    [every $c in * satisfies ($c/name() = $idml2xml:content-group-children)]"
    mode="idml2xml:DocumentResolveTextFrames_DISABLED2" priority="2">
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
    mode="idml2xml:DocumentResolveTextFrames_DISABLED2" >
    <xsl:comment>HANDLE ME! (I'm in Document.xsl)</xsl:comment>
    <xsl:message>HANDLE ME! (I'm in Document.xsl)</xsl:message>
    <xsl:next-match/>    
  </xsl:template>

    

  <xsl:template match="TextFrame[
                         parent::Spread or 
                         parent::Group
                       ]" mode="idml2xml:DocumentResolveTextFrames_DISABLED2">
    <xsl:copy>
      <xsl:apply-templates select="@* | *" mode="#current" />
      <xsl:apply-templates select="key( 'story', current()/@ParentStory )" mode="#current">
        <xsl:with-param name="is-a-grouped-spread-textframe" select="true()" tunnel="yes"/>
        <xsl:with-param name="textframe" select="." tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="TextFrame[@PreviousTextFrame eq 'n']" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy>
      <xsl:apply-templates select="@* | *" mode="#current" />
      <xsl:apply-templates select="key( 'story', current()/@ParentStory )" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:function name="idml2xml:is-group-without-frame" as="xs:boolean">
    <xsl:param name="group" as="element(Group)"/>
    <xsl:sequence select="not($group/TextFrame[@PreviousTextFrame eq 'n'])"/>
  </xsl:function>

  <xsl:template match="Story" mode="idml2xml:DocumentResolveTextFrames_DISABLED2">
    <xsl:param name="textframe" as="node()?" tunnel="yes"/>
    <xsl:param name="is-a-grouped-spread-textframe" tunnel="yes"/>
    
    <xsl:variable name="preceding-non-frames" as="element(*)*"
      select="$textframe/preceding-sibling::*[name() = $idml2xml:shape-element-names or self::Group[idml2xml:is-group-without-frame(.)]]"/>
    <xsl:variable name="following-non-frames" as="element(*)*"
      select="$textframe/following-sibling::*[name() = $idml2xml:shape-element-names or self::Group[idml2xml:is-group-without-frame(.)]]"/>
    <xsl:choose>
      <xsl:when test="$is-a-grouped-spread-textframe and
                      $textframe/parent::Group and 
                      (
                        $preceding-non-frames or 
                        $following-non-frames
                      )">
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current" />
          <Group>
            <xsl:choose>
              <xsl:when test="$textframe/preceding-sibling::TextFrame[@PreviousTextFrame eq 'n']">
                <xsl:variable name="last-preceding-textframe" as="element(TextFrame)"
                  select="$textframe/preceding-sibling::TextFrame[@PreviousTextFrame eq 'n'][1]"/>
                <xsl:if
                  test="exists($preceding-non-frames[ . &gt;&gt; $last-preceding-textframe ])">
                  <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Rectangle">
                    <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]">
                      <xsl:apply-templates
                        select="$preceding-non-frames[ . &gt;&gt; $last-preceding-textframe ]"
                        mode="#current"/>
                    </CharacterStyleRange>
                    <Br/>
                  </ParagraphStyleRange>
                </xsl:if>
              </xsl:when>
              <xsl:when test="exists($preceding-non-frames)">
                <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Rectangle">
                  <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]">
                    <xsl:apply-templates
                      select="$preceding-non-frames"
                      mode="#current">
                      <xsl:with-param name="in-group-frames" select="self::Group//TextFrame" as="element(TextFrame)*"
                        tunnel="yes"/>
                    </xsl:apply-templates>
                  </CharacterStyleRange>
                  <Br/>
                </ParagraphStyleRange>
              </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="node()" mode="#current" />
            <xsl:if test="not($textframe/following-sibling::TextFrame[@PreviousTextFrame eq 'n'])
                          and exists($following-non-frames)">
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Rectangle">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]">
                  <xsl:apply-templates select="$following-non-frames" mode="#current">
                    <xsl:with-param name="in-group-frames" select="self::Group//TextFrame" as="element(TextFrame)*" tunnel="yes"/>
                  </xsl:apply-templates>
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
  <xsl:template match="TextFrame/@*" mode="idml2xml:DocumentResolveTextFrames" priority="-0.125" />
  <xsl:template match="@AppliedObjectStyle" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:attribute name="idml2xml:objectstyle" select="replace( idml2xml:substr( 'a', ., 'ObjectStyle/' ), '%3a', ':' )" />
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
  <!-- GI 2013-05-02: Why? Counterexample: SR 118, caption of Table 11.2. Inline image 
    in a Rectangle with  <AnchoredObjectSetting AnchorYoffset="-3.1590519067328278"/>
    There shouldn’t be a paragraph break after it. --> 
  <xsl:template mode="idml2xml:DocumentResolveTextFrames_DISABLED"
    match="*[name() = $idml2xml:shape-element-names][not(ancestor::Spread)][AnchoredObjectSetting and not(AnchoredObjectSetting/@AnchoredPosition)]" priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
    <Br reason="Rectangle_anchored" />
  </xsl:template>

  <!-- -->
  <xsl:template mode="idml2xml:DocumentResolveTextFrames_DISABLED2"
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
