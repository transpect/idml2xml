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
      <xsl:variable name="spreads" select="idPkg:Spread/Spread" as="element(Spread)*"/>
      <xsl:for-each select="$spreads">
        <xsl:variable name="pos" select="position()" as="xs:integer" />
        <idml2xml:sidebar remap="Spread" xml:id="spread_{position()}">
          <xsl:for-each select="*[local-name() = ('Page', 'TextFrame', $idml2xml:shape-element-names)]">
            <anchor linkend="{lower-case(local-name())}_{position()}" Self="{@Self}"/>
          </xsl:for-each>
        </idml2xml:sidebar>
        <xsl:for-each select="Page">
          <idml2xml:sidebar remap="Page" pos-in-book="{@Name}" pos-in-doc="{position()}" xml:id="page_{position()}" Self="{@Self}">
            <xsl:attribute name="idml2xml:width" 
              select="concat(
                      tokenize(
                        (@GeometricBounds, //DocumentPreference/@PageWidth)[1],
                        ' ')[4], 
                      'pt'
                    )"/>
          <xsl:attribute name="idml2xml:height" 
            select="concat(
                      tokenize(
                        (@GeometricBounds, //DocumentPreference/@PageWidth)[1],
                        ' ')[3], 
                      'pt'
                    )"/>
          <xsl:attribute name="idml2xml:margin" 
            select="concat(
                      (MarginPreference/@Top, //MarginPreference/@Top)[1], 'pt ',
                      (MarginPreferenceMargin/@Right, //MarginPreference/@Right)[1], 'pt ',
                      (MarginPreferenceMargin/@Bottom, //MarginPreference/@Bottom)[1], 'pt ',
                      (MarginPreference/@Left, //MarginPreference/@Left)[1], 'pt'
                    )"/>
          </idml2xml:sidebar>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:copy-of select="idPkg:Graphic" />
      <xsl:copy-of select="idPkg:Styles" />
      <idml2xml:hyper>
        <xsl:copy-of select="HyperlinkPageDestination | HyperlinkURLDestination | Hyperlink | HyperlinkPageItemSource" />
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
                                       | Group[.//(  TextFrame[idml2xml:is-story-origin(.)] 
                                                   | *[name() = $idml2xml:shape-element-names])]
                                       | *[name() = $idml2xml:shape-element-names]
                                    ),
                //XmlStory" 
        mode="idml2xml:DocumentResolveTextFrames"/>
    </xsl:copy>
  </xsl:template>


  <!-- temporary workaround to save page source informations for indexterm`s in freely placed TextFrame`s -->
  <xsl:template match="PageReference" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy>
      <xsl:if test="key('TextFrame-by-ParentStory', ancestor::Story/@Self)/@PreviousTextFrame eq 'n' and 
                    key('TextFrame-by-ParentStory', ancestor::Story/@Self)/@NextTextFrame eq 'n'">
        <xsl:attribute name="idml2xml:sourcepage" 
          select="key('TextFrame-by-ParentStory', ancestor::Story/@Self)/preceding-sibling::Page[last()]/@Name"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- Groups that contain text frames with a StoryID will be moved to the location 
       of the corresponding StoryRef if such exists. They will be removed here -->
  <xsl:template match="Group[.//TextFrame[idml2xml:conditional-text-anchored(.)]]"
    mode="idml2xml:DocumentResolveTextFrames" priority="4"/>

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
  <!-- we do not allow StoryIDs/StoryRefs that consist of whistespace only -->
  <xsl:key name="Story-by-StoryID" match="Story[.//@AppliedConditions[. = 'Condition/StoryID']]
                                               [matches(string-join(for $e in .//*[@AppliedConditions = 'Condition/StoryID'] return idml2xml:text-content($e), ''), '\S')]" 
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
    <xsl:variable name="same-id-stories" as="element(Story)+" select="key('Story-by-StoryID', $id, root($frame))"/>
    <xsl:variable name="referencing-story" as="element(Story)*" select="key('referencing-Story-by-StoryID', $id, root($frame))"/>
    <xsl:sequence select="if ($id and $id != '' and count($same-id-stories) eq 1) 
                          then exists($referencing-story) and ($referencing-story/@Self != $frame/@ParentStory) 
                          else false()"/>
  </xsl:function>

  <xsl:template match="*[@AppliedConditions eq 'Condition/StoryRef']" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="story" select="key('Story-by-StoryID', idml2xml:text-content(.))" as="element(Story)*"/>
      <xsl:choose>
        <xsl:when test="count($story) eq 0"><!-- doesn’t resolve, reproduce applied conditions and content 
          so that Schematron can report non-resolution -->
          <xsl:attribute name="idml2xml:reason" select="'NO_Story'"/>
          <xsl:copy-of select="@AppliedConditions, node()"/>
        </xsl:when>
        <xsl:when test="count($story) gt 1">
          <xsl:message>Multiple occurrences of StoryID <xsl:value-of select="idml2xml:text-content(.)"/>. 
            Using only the first Story (with @Self <xsl:value-of select="$story/@Self"/>).
          </xsl:message>
          <xsl:attribute name="idml2xml:reason" select="'MULT_StoryID'"/>
          <xsl:copy-of select="@AppliedConditions, node()"/>
        </xsl:when>
        <xsl:when test="not($story/@Self = ancestor::Story/@Self)">
          <!-- If the looked-up story has the same @Self as the current StoryRef, do nothing. -->
          <xsl:variable name="anchored-frame" select="key('TextFrame-by-ParentStory', $story/@Self)" as="element(TextFrame)"/>
          <xsl:variable name="potential-group" select="($anchored-frame/ancestor::Group[last()], $anchored-frame)[1]"
            as="element(*)"/>
          <xsl:choose>
            <xsl:when test="$potential-group/self::Group">
              <xsl:for-each select="$potential-group">
                <xsl:copy>
                  <xsl:apply-templates select="@*, node()" mode="#current"/>
                </xsl:copy>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="$potential-group">
                <xsl:copy>
                  <xsl:apply-templates select="@*, node(), $story" mode="#current"/>
                </xsl:copy>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- otherwise: the story is anchored within itself, don’t do anything -->
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@AppliedConditions eq 'Condition/FigureRef']" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" group-ending-with="Br">
        <xsl:variable name="group-container" as="element(*)?">
          <GroupContainer>
            <xsl:copy-of select="current-group()"/>
          </GroupContainer>
         </xsl:variable>
        <xsl:copy-of select="for $i in tokenize(normalize-space(idml2xml:text-content($group-container)), ' ') return ((//Rectangle[ends-with(.//@LinkResourceURI, $i)], (//Rectangle[.//KeyValuePair[@Key = 'px:bildFileName'][@Value = $i]])))[1]"/>
        <xsl:if test="current-group()[descendant-or-self::*:Br]">
          <xsl:copy-of select="current-group()[descendant-or-self::*:Br]"/>"
        </xsl:if>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="idml2xml:split-figure-ref" as="xs:string?">
    <xsl:param name="elt" as="element(*)?"/>
    <xsl:variable name="group"  as="element(*)?">
    <xsl:element name="{name($elt)}">
      <xsl:copy-of select="$elt/@*"/>
        <xsl:for-each select="$elt/node()">
          <xsl:choose>
            <xsl:when test="following-sibling::*[1][local-name() = 'Br']">
              <xsl:element name="{name(.)}">
                <xsl:copy-of select="@*"/>
                <xsl:copy-of select="node()"/>
                <xsl:text> </xsl:text>
              </xsl:element>
            </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="."/>
              </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
    </xsl:element>
    </xsl:variable>
    <xsl:sequence select="normalize-space(idml2xml:text-content($group))"/>
  </xsl:function>
  
  <xsl:template match="Rectangle[some $ref in //*[@AppliedConditions eq 'Condition/FigureRef']
                                 satisfies 
                                 (
                                    some $token in tokenize(idml2xml:split-figure-ref($ref), ' ') 
                                    satisfies (ends-with(current()//@LinkResourceURI, $token) or ($token = current()//KeyValuePair[@Key = 'px:bildFileName']/@Value))
                                  )
                                  ]"
    mode="idml2xml:DocumentResolveTextFrames" priority="3"/>

  <xsl:function name="idml2xml:text-content" as="xs:string?">
    <xsl:param name="elt" as="element(*)?"/>
    <xsl:sequence select="string-join($elt//Content[normalize-space()], '')"/>
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
                mode="idml2xml:DocumentResolveTextFrames">
    <!-- Discard StoryIDs that are referenced somewhere. 
      In order to look up referencing stories (with a correpsonding StoryRef in it), 
      we concatenate all StoryIDs in this story. As a consequence, if there are multiple
      StoryIDs in this story (which is an error), the concatenated IDs will probably not resolve,
      therefore this StoryID will not be discarded by this template and may be later checked for
      by a Schematron rule. -->
    <!-- Another type of error is: there are identical StoryIDs in different Stories. Will keep StoryIDs then, too. -->
    <xsl:variable name="concat-id" as="xs:string"
      select="string-join(for $e in ancestor::Story//*[@AppliedConditions = 'Condition/StoryID'] return idml2xml:text-content($e), '')"/>
    <xsl:variable name="same-id-stories" as="element(Story)+" select="key('Story-by-StoryID', $concat-id)"/>
    <xsl:if test="count($same-id-stories) gt 1">
      <xsl:copy>
        <xsl:attribute name="idml2xml:reason" select="'MULT_StoryID'"/>
        <xsl:copy-of select="@*, node()" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>

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

  <xsl:template match="TextFrame[@PreviousTextFrame eq 'n']" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:copy>
      <xsl:apply-templates select="@* | *" mode="#current" />
      <xsl:apply-templates select="key( 'Story-by-Self', current()/@ParentStory )" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:function name="idml2xml:is-group-without-frame" as="xs:boolean">
    <xsl:param name="group" as="element(Group)"/>
    <xsl:sequence select="not($group/TextFrame[@PreviousTextFrame eq 'n'])"/>
  </xsl:function>

  <xsl:template match="TextFrame/*" mode="idml2xml:DocumentResolveTextFrames" />
  <xsl:template match="TextFrame/@*" mode="idml2xml:DocumentResolveTextFrames" priority="-0.125" />
  <xsl:template match="@AppliedObjectStyle" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:if test="not(. = 'n')">
      <xsl:attribute name="idml2xml:objectstyle" select="replace( idml2xml:substr( 'a', ., 'ObjectStyle/' ), '%3a', ':' )" />
    </xsl:if>
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
             and not($output-items-not-on-workspace = ('yes','1','true'))
           ]" 
    mode="idml2xml:DocumentResolveTextFrames" />

  <!-- element Change: textual changes -->

  <xsl:template 
    match="Change[ not($output-deleted-text = ('yes','1','true')) and @ChangeType eq 'DeletedText']" 
    mode="idml2xml:DocumentResolveTextFrames" />

  <xsl:template 
    match="Change[ @ChangeType = ('InsertedText', 'MovedText') ]" 
    mode="idml2xml:DocumentResolveTextFrames">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- remove (binary) metadata to reduce debugging file size -->
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

  <xsl:template match="Group" mode="idml2xml:DocumentResolveTextFrames">
    <xsl:variable name="all-objects" as="element(*)*" select="*"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="objects-coordinates">
        <xsl:apply-templates select="*" mode="idml2xml:Geometry"/>
      </xsl:variable>
      <xsl:variable name="ordered-objects">
          <xsl:perform-sort select="$objects-coordinates/point">
            <xsl:sort select="@coord-y" data-type="number" order="ascending"/>
            <xsl:sort select="@coord-x" data-type="number" order="ascending"/>
          </xsl:perform-sort>
      </xsl:variable>
      <xsl:for-each select="($ordered-objects/point)">
        <xsl:apply-templates select="$all-objects[@Self = current()/@Self]" mode="#current"/>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[Properties/PathGeometry/GeometryPathType]" mode="idml2xml:Geometry" as="item()*">
    <xsl:variable name="transformation-matrix" as="xs:double+" select="for $value in tokenize(@ItemTransform, ' ') return xs:double($value)"/>
    <xsl:variable name="id" select="@Self"/>
    <xsl:variable name="original-point-array" as="element(point)+">
      <xsl:for-each select="Properties/PathGeometry/GeometryPathType/PathPointArray/PathPointType">
        <point>
          <xsl:for-each select="tokenize(@Anchor, ' ')">
            <coord>
              <xsl:sequence select="xs:double(.)"/>
            </coord>
          </xsl:for-each>
        </point>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="translated-point-array" as="element(point)*">
      <xsl:for-each select="$original-point-array">
        <point>
          <xsl:attribute name="Self" select="$id"/>  
          <xsl:attribute name="coord-x" select="coord[1] + $transformation-matrix[5]"/>  
          <xsl:attribute name="coord-y" select="coord[2] + $transformation-matrix[6]"/>  
        </point>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="lowest-y" select="min($translated-point-array//@coord-y)" as="xs:double"/>
    <xsl:variable name="point-with-lowest-y-coords" as="element(point)*">
      <xsl:perform-sort select="$translated-point-array[@coord-y = $lowest-y]">
        <xsl:sort data-type="number" order="ascending" select="@coord-x"/>
      </xsl:perform-sort>
    </xsl:variable>
    <xsl:variable name="first-point-on-page" select="$point-with-lowest-y-coords[1]"/>
    <xsl:sequence select="$first-point-on-page"/>
  </xsl:template>

</xsl:stylesheet>
