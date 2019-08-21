<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
    version="2.0"
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs = "http://www.w3.org/2001/XMLSchema"
    xmlns:css="http://www.w3.org/1996/css"
    xmlns:aid = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5 = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://transpect.io/idml2xml"
    xmlns:tr="http://transpect.io"
    xmlns:xlink = "http://www.w3.org/1999/xlink"
    xmlns:dbk = "http://docbook.org/ns/docbook"
    xmlns:hub = "http://transpect.io/hub"
    xmlns:mml="http://www.w3.org/1998/Math/MathML"
    xmlns="http://docbook.org/ns/docbook"
    exclude-result-prefixes="idPkg aid5 aid xs xlink dbk tr css hub"
    >

  <xsl:import href="../propmap.xsl"/>
	<xsl:key name="idml2xml:list-styles" match="css:rule" use="@css:list-style-type"/>
  <xsl:key name="idml2xml:style-by-role" match="style | css:rule" use="(@role, @name)[1]" />
  <xsl:key name="idml2xml:element-by-pstyle" match="*[@aid:pstyle]" use="@aid:pstyle" />
	
  <xsl:variable 
      name="hubformat-elementnames-whitelist"
      select="('alt', 'anchor', 'book', 'hub', 'Body', 'para', 'info', 'informaltable', 'table', 'tgroup', 
               'colspec', 'tbody', 'row', 'entry', 'mediaobject', 'inlinemediaobject', 'tab', 'tabs', 'br',
               'imageobject', 'imagedata', 'phrase', 'emphasis', 'sidebar',
               'superscript', 'subscript', 'link', 'xref', 'footnote', 'note', 'mml:math', 
               'keywordset', 'keyword', 'indexterm', 'primary', 'secondary', 'tertiary',
               'see', 'seealso', 'date', 'author', 'personname', 'tfoot', 'thead',
               'css:rules', 'css:rule', 'linked-style', 'inlineequation', 'equation',
               'styles', 'parastyles', 'inlinestyles', 'objectstyles', 'cellstyles', 'tablestyles', 'style',
               $level-element-name
              )" as="xs:string+"/>


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-add-properties -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- see ../propmap.xsl -->
  
  <xsl:template match="idml2xml:doc" mode="idml2xml:XML-Hubformat-add-properties"
    xmlns="http://docbook.org/ns/docbook">
    <xsl:element name="{if ($hub-version eq '1.0') then 'Body' else 'hub'}">
      <xsl:attribute name="version" select="concat('5.1-variant le-tex_Hub-', $hub-version)"/>
      <xsl:attribute name="css:version" select="concat('3.0-variant le-tex_Hub-', $hub-version)" />
      <xsl:if test="not($hub-version eq '1.0')">
        <xsl:attribute name="css:rule-selection-attribute" select="'role'" />
      </xsl:if>
      <info>
        <keywordset role="hub">
          <keyword role="source-basename"><xsl:value-of select="$idml2xml:basename"/></keyword>
          <keyword role="source-dir-uri"><xsl:value-of select="$src-dir-uri"/></keyword>
          <keyword role="archive-dir-uri"><xsl:value-of select="$archive-dir-uri"/></keyword>
          <keyword role="source-paths"><xsl:value-of select="if ($srcpaths = 'yes') then 'true' else 'false'"/></keyword>
          <keyword role="used-rules-only">
            <xsl:value-of select="not($all-styles = 'yes')"/>
          </keyword>
          <keyword role="formatting-deviations-only">true</keyword>
          <keyword role="source-type">idml</keyword>
          <xsl:if test="/*/@TOCStyle_Title">
            <keyword role="toc-title">
              <xsl:value-of select="/*/@TOCStyle_Title"/>
            </keyword>
          </xsl:if>
          <xsl:if test="/*/@TypeAreaWidth">
            <keyword role="type-area-width">
              <xsl:value-of select="/*/@TypeAreaWidth"/>
            </keyword>
          </xsl:if>
          <xsl:if test="idPkg:Preferences/FootnoteOption/Properties/RestartNumbering">
            <keyword role="footnote-restart">
              <xsl:value-of select="if (starts-with(idPkg:Preferences/FootnoteOption/Properties/RestartNumbering, 'Dont')) then 'false' else 'true'"/>
            </keyword>
          </xsl:if>
          <xsl:if test="idml2xml:endnotes/EndnoteOption/Properties/RestartEndnoteNumbering">
            <keyword role="endnote-restart">
              <xsl:value-of select="if (starts-with(idml2xml:endnotes/EndnoteOption/Properties/RestartEndnoteNumbering, 'Continuous')) then 'false' else 'true'"/>
            </keyword>
          </xsl:if>
        </keywordset>
        <xsl:choose>
          <xsl:when test="$hub-version eq '1.0'">
            <xsl:call-template name="idml2xml:hub-1.0-styles">
              <xsl:with-param name="version" select="$hub-version" tunnel="yes"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="idml2xml:hub-1.1-styles">
              <xsl:with-param name="version" select="$hub-version" tunnel="yes"/>
              <xsl:with-param name="all-styles" select="$all-styles" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <!-- temporary save idml2xml:indexterms, will be removed in XML-Hubformat-cleanup-paras-and-br -->
        <xsl:sequence select="idml2xml:indexterms"/>
      </info>
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="idml2xml:hub-1.0-styles">
    <styles>
      <parastyles>
        <xsl:apply-templates
          select="key('idml2xml:style', for $s in distinct-values(//*/@aid:pstyle) return idml2xml:generate-style-name-variants('ParagraphStyle', $s) )"
          mode="#current">
          <xsl:sort select="@Name"/>
        </xsl:apply-templates>
      </parastyles>
      <inlinestyles>
        <xsl:apply-templates
          select="key('idml2xml:style', for $s in distinct-values(//*/@aid:cstyle) return idml2xml:generate-style-name-variants('CharacterStyle', $s) )"
          mode="#current">
          <xsl:sort select="@Name"/>
        </xsl:apply-templates>
      </inlinestyles>
      <tablestyles>
        <xsl:apply-templates
          select="key('idml2xml:style', for $s in distinct-values(//*/@aid5:tablestyle) return idml2xml:generate-style-name-variants('TableStyle', $s) )"
          mode="#current">
          <xsl:sort select="@Name"/>
        </xsl:apply-templates>
      </tablestyles>
      <cellstyles>
        <style role="None"/>
        <xsl:apply-templates
          select="key(
                    'idml2xml:style', 
                    for $s 
                    in distinct-values((
                         //*/@aid5:cellstyle,
                         //TableStyle[not(@HeaderRegionSameAsBodyRegion eq 'true')]/@HeaderRegionCellStyle,
                         //TableStyle/@BodyRegionCellStyle,
                         //TableStyle[not(@FooterRegionSameAsBodyRegion eq 'true')]/@FooterRegionCellStyle
                       ))
                    return idml2xml:generate-style-name-variants('CellStyle', $s) )"
          mode="#current">
          <xsl:sort select="@Name"/>
        </xsl:apply-templates>
      </cellstyles>
    </styles>
  </xsl:template>

  <xsl:template name="idml2xml:hub-1.1-styles">
    <xsl:param name="all-styles" as="xs:string"/>
    <css:rules>
      <xsl:apply-templates
        select="if ($all-styles eq 'yes')
                then /*/idPkg:Styles//ParagraphStyle
                else key('idml2xml:style', for $s in distinct-values(//*/@aid:pstyle) return idml2xml:generate-style-name-variants('ParagraphStyle', $s) )"
        mode="#current">
        <xsl:sort select="@Name"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="if ($all-styles eq 'yes')
                then /*/idPkg:Styles//CharacterStyle
                else key(
                  'idml2xml:style', 
                  for $s in (
                    distinct-values(//*/@aid:cstyle), 
                    for $n in //CharacterStyle[@Name ne '$ID/[No character style]'][
                      @Self = //ParagraphStyle/Properties/NumberingCharacterStyle] 
                    return substring-after($n/@Self, 'CharacterStyle/')
                  ) return idml2xml:generate-style-name-variants('CharacterStyle', $s)
                )"
        mode="#current">
        <xsl:sort select="@Name"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="if ($all-styles eq 'yes')
                then /*/idPkg:Styles//TableStyle
                else key('idml2xml:style', for $s in distinct-values(//*/@aid5:tablestyle) return idml2xml:generate-style-name-variants('TableStyle', $s) )"
        mode="#current">
        <xsl:sort select="@Name"/>
      </xsl:apply-templates>
      <!--<css:rule name="None" layout-type="cell"/>-->
      <xsl:apply-templates
        select="if ($all-styles eq 'yes')
                then /*/idPkg:Styles//CellStyle
                else key(
                       'idml2xml:style', 
                       for $s in distinct-values((
                         //*/@aid5:cellstyle,
                         //TableStyle[not(@HeaderRegionSameAsBodyRegion eq 'true')]/@HeaderRegionCellStyle,
                         //TableStyle/@BodyRegionCellStyle,
                         //TableStyle[not(@FooterRegionSameAsBodyRegion eq 'true')]/@FooterRegionCellStyle
                       )) return idml2xml:generate-style-name-variants('CellStyle', $s) )"
        mode="#current">
        <xsl:sort select="@Name"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="if ($all-styles eq 'yes')
        then /*/idPkg:Styles//ObjectStyle[not(@Name = '$ID/[None]')] (: there is a name clash between cell style $ID/[None] and this one :)
        else key('idml2xml:style', for $s in distinct-values(//*/@idml2xml:objectstyle) return idml2xml:generate-style-name-variants('ObjectStyle', $s) )"
        mode="#current">
        <xsl:sort select="@Name"/>
      </xsl:apply-templates>
    </css:rules>
  </xsl:template>
  
  <xsl:template match="ParagraphStyle | CharacterStyle | TableStyle | CellStyle | ObjectStyle" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:param name="wrap-in-style-element" select="true()" as="xs:boolean"/>
    <xsl:param name="version" tunnel="yes" as="xs:string"/>
    <xsl:variable name="atts" as="node()*">
      <xsl:if test="self::ParagraphStyle[not(Properties/BasedOn)]">
        <xsl:apply-templates select="/*/idPkg:Preferences/TextDefault/(
                                        @NumberingApplyRestartPolicy
                                      | @NumberingContinue
                                      | NumberingFormat
                                      (: | probably need to consider NumberingRestartPolicies, too :) 
                                    )" mode="#current">
            <xsl:with-param name="wrap-in-style-element" select="false()"/>
          </xsl:apply-templates>
      </xsl:if>
      <xsl:apply-templates select="if (Properties/BasedOn/@type = 'object' and Properties/BasedOn ne @Self) 
                                   then key('idml2xml:style', idml2xml:StyleNameEscape(Properties/BasedOn))[name() = current()/name()]
                                   else 
                                     if (Properties/BasedOn/@type = 'string' and Properties/BasedOn ne @Self)
                                     then key('idml2xml:style-by-Name', Properties/BasedOn)[name() = current()/name()]
                                     else ()" mode="#current">
        <xsl:with-param name="wrap-in-style-element" select="false()"/>
      </xsl:apply-templates>
      <xsl:variable name="mergeable-atts" as="element(*)*">
        <xsl:apply-templates select="@*, Properties/*[not(self::BasedOn or self::MathToolsML[mml:math])]" mode="#current" />
      </xsl:variable>
      <xsl:for-each-group select="$mergeable-atts[self::idml2xml:attribute]" group-by="@name">
        <xsl:variable name="att" as="element(idml2xml:attribute)">
          <idml2xml:attribute name="{current-grouping-key()}"><xsl:value-of select="distinct-values(current-group())" /></idml2xml:attribute>
        </xsl:variable>
        <xsl:copy-of select="$att" copy-namespaces="no"/>
      </xsl:for-each-group>
      <xsl:sequence select="$mergeable-atts[not(self::idml2xml:attribute)]"/>
    </xsl:variable>
    <xsl:comment select="@Self"/>
    <xsl:if test="not(Properties/BasedOn)">
      <xsl:comment>TextDefault</xsl:comment>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$wrap-in-style-element">
        <xsl:element name="{if($version eq '1.0') then 'style' else 'css:rule'}">
          <!-- In order to get CSS-compliant style names, we’ll have to replace
            some characters such as space and colon later on. We’ll leave it 
            as idml2xml:StyleName for the time being and take care of it in a later mode. -->
          <xsl:attribute name="{if($version eq '1.0') then 'role' else 'name'}" select="idml2xml:StyleName(@Name)"/>
          <xsl:attribute name="native-name" select="@Name"/>
          <xsl:apply-templates select="." mode="idml2xml:XML-Hubformat-add-properties_layout-type"/>
          <xsl:sequence select="$atts"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$atts"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ParagraphStyle | CharacterStyle | TableStyle | CellStyle | ObjectStyle"
    mode="idml2xml:XML-Hubformat-add-properties_layout-type">
    <xsl:param name="version" tunnel="yes" as="xs:string"/>
    <xsl:if test="not($version eq '1.0')">
      <xsl:attribute name="layout-type" select="if (self::ParagraphStyle)
                                                then 'para'
                                                else if (self::CharacterStyle)
                                                  then 'inline'
                                                  else if (self::TableStyle)
                                                    then 'table'
                                                    else if (self::CellStyle)
                                                      then 'cell'
                                                      else 'object'"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Properties" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="MathToolsML[mml:math]" mode="idml2xml:XML-Hubformat-add-properties">
    <inlineequation role="mathtools">
      <math xmlns="http://www.w3.org/1998/Math/MathML">
        <xsl:sequence select="mml:math/node()"/>
      </math>
    </inlineequation>
  </xsl:template>
  
  <xsl:template match="Properties/BasedOn" mode="idml2xml:XML-Hubformat-add-properties" />

  <xsl:template match="*[self::Properties or self::Image][parent::*[name() = $idml2xml:shape-element-names]]" mode="idml2xml:XML-Hubformat-add-properties">
    <!-- what is this for? Had to exclude Link bc otherwise the URI would be duplicated --> 
    <xsl:apply-templates select="node() except Link" mode="#current"/>
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- 
remap and output indesign attribute+property settings to hub format
see: idml/_IDML_Schema_RelaxNGCompact
http://cssdk.host.adobe.com/sdk/1.5/docs/WebHelp/references/csawlib/com/adobe/csawlib/CSEnumBase.html or
http://wwwimages.adobe.com/www.adobe.com/content/dam/Adobe/en/devnet/indesign/cs55-docs/IDML/idml-specification.pdf
  -->
  <xsl:template match="@* | Properties/* | ListItem/*" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:variable name="prop" select="key('idml2xml:prop', idml2xml:propkey(.), $idml2xml:propmap)" />
    <xsl:variable name="raw-output" as="element(*)*">
      <xsl:apply-templates select="$prop" mode="#current">
        <xsl:with-param name="val" select="." tunnel="yes" />
      </xsl:apply-templates>      
      <xsl:if test="empty($prop)">
        <idml2xml:attribute name="idml2xml:{local-name()}"><xsl:value-of select="." /></idml2xml:attribute>
      </xsl:if>
    </xsl:variable>
    <xsl:sequence select="$raw-output" />
  </xsl:template>
  
  <xsl:template match="Properties/SameParaStyleSpacing[. eq 'SetIgnore']" mode="idml2xml:XML-Hubformat-add-properties" priority="1"/>

  <xsl:template match="*[name() = $idml2xml:shape-element-names]/@Self" mode="idml2xml:XML-Hubformat-add-properties" priority="4">
    <idml2xml:attribute name="{name()}">
      <xsl:value-of select="."/>
    </idml2xml:attribute>
  </xsl:template>
    
  <xsl:template match="*[name() = $idml2xml:shape-element-names]" 
                mode="idml2xml:XML-Hubformat-add-properties" priority="4">
    <xsl:copy>
      <xsl:copy-of select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[@idml2xml:tag-source = 'embedded']" 
                mode="idml2xml:XML-Hubformat-add-properties" priority="4">
    <xsl:copy>
      <xsl:copy-of select="@* except (@idml2xml:tag-source | @srcpath)"/>
      <xsl:apply-templates select="@srcpath" mode="idml2xml:XML-Hubformat-add-properties_tagged"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-add-properties_tagged">
    <xsl:attribute name="{name()}" select="string-join(
                                            for $s in tokenize(., '\s+') return 
                                              replace($s , $src-dir-uri-regex, ''),
                                            ' '
                                          )"/>
  </xsl:template>
  
  <xsl:variable name="src-dir-uri-regex" as="xs:string" 
    select="replace(
              replace(
                $src-dir-uri, 
                '([-+.])', 
                '\\$1'
              ), 
              '^file:/+', 
              '^file:/+'
            )"/>
  
  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-add-properties">
    <idml2xml:attribute name="srcpath"> 
      <xsl:value-of select="string-join(
                              for $s in tokenize(., '\s+') return 
                                replace($s , $src-dir-uri-regex, ''),
                              ' '
                            )"/>
    </idml2xml:attribute>
  </xsl:template>

  <xsl:function name="idml2xml:propkey" as="xs:string">
    <xsl:param name="prop" as="node()" />
    <xsl:choose>
      <xsl:when test="$prop/../self::Properties">
        <xsl:sequence select="name($prop)" />
      </xsl:when>
      <xsl:when test="$prop instance of attribute()">
        <xsl:sequence select="name($prop)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat(name($prop/..), '/', name($prop))" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="prop" mode="idml2xml:XML-Hubformat-add-properties" as="node()*">
    <xsl:param name="val" as="node()" tunnel="yes" />
    <xsl:variable name="atts" as="element(*)*">
      <!-- in the following line, val is a potential child of prop (do not cofuse with $val)! -->
      <xsl:apply-templates select="@type, val" mode="#current" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="empty($atts) and @default">
        <idml2xml:attribute name="{@target-name}"><xsl:value-of select="@default" /></idml2xml:attribute>
      </xsl:when>
      <xsl:when test="empty($atts)" />
      <xsl:otherwise>
        <xsl:sequence select="$atts" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="val" mode="idml2xml:XML-Hubformat-add-properties" as="element(*)?">
    <xsl:apply-templates select="@eq, @match" mode="#current" />
  </xsl:template>

  <xsl:key name="idml2xml:color" match="idPkg:Graphic/Color" use="@Self" />
  <xsl:key name="idml2xml:tint" match="idPkg:Graphic/Tint" use="@Self" />
  <xsl:key name="idml2xml:gradient" match="idPkg:Graphic/Gradient" use="@Self" />
  
  <xsl:template match="prop/@type" mode="idml2xml:XML-Hubformat-add-properties" as="node()*">
    <xsl:param name="val" as="node()" tunnel="yes">
      <!-- Val may be (see template where with-param name="val" is passed): @* | Properties/* | ListItem/* -->
    </xsl:param>
    <xsl:choose>

      <xsl:when test=". eq 'bullet-char'">
        <idml2xml:attribute name="{../@target-name}">
          <xsl:choose>
            <xsl:when test="$val/@BulletCharacterType eq 'GlyphWithFont'">
              <xsl:message>INFO: Unsupported bullet character type 'GlyphWithFont' for char <xsl:value-of select="$val/@BulletCharacterValue"/>. Falling back to U+2022
              </xsl:message>
              <xsl:value-of select='"&apos;&#x2022;&apos;"' />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='concat("&apos;", codepoints-to-string(xs:integer($val/@BulletCharacterValue)), "&apos;")' />
            </xsl:otherwise>
          </xsl:choose>
        </idml2xml:attribute>
      </xsl:when>
      
      <xsl:when test=". eq 'color'">
        <xsl:variable name="context-name" select="if ($val/parent::Properties) 
                                                  then $val/../../name() 
                                                  else $val/../name()" as="xs:string" />
        <xsl:variable name="target-name" select="(../context[matches($context-name, @match)]/@target-name, ../@target-name)[1]" as="xs:string" />
        <xsl:choose>
          <xsl:when test="matches($val, '^(Stop)?Color')">
            <idml2xml:attribute name="{$target-name}">
              <xsl:apply-templates select="key('idml2xml:color', $val, root($val))" mode="#current" >
                <!-- UnderlineColor has its tint value as a number in ../../@UnderlineTint,
                  while other Colors are tinted by means of a Tint element -->
                <xsl:with-param name="multiplier">
                  <xsl:choose>
                    <xsl:when test="matches(($val/name(),'')[1], '^(Stroke|Underline)Color')">
                      <xsl:sequence select="if ($val/(../.., ..)/@*[name() = replace($val/name(), 'Color', 'Tint')] = '-1') 
                                            then 1.0 
                                            else number(($val/(../.., ..)/@*[name() = replace($val/name(), 'Color', 'Tint')], 100)[1]) * 0.01"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select="1.0"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
              </xsl:apply-templates>
            </idml2xml:attribute>
          </xsl:when>
          <xsl:when test="matches($val, '^Tint')">
            <xsl:variable name="tint-decl" select="key('idml2xml:tint', $val, root($val))[1]" as="element(Tint)" />
            <idml2xml:attribute name="{$target-name}">
              <xsl:apply-templates select="key(
                'idml2xml:color',
                $tint-decl/@BaseColor,
                root($val)
                )" mode="#current" />
            </idml2xml:attribute>
            <xsl:choose>
              <xsl:when test="matches($target-name, 'css:border-((top|bottom|left|right)-)?color')">
                <!-- if borders are tinted no new fill-value attribute must be created! -->
                <xsl:if test=" $tint-decl/@TintValue castable as xs:integer and not(xs:integer($tint-decl/@TintValue) eq -1)">
                  <idml2xml:attribute name="{replace($target-name, '^css:border-((top|bottom|left|right)-)?color', 'border-$1tint')}">
                    <xsl:value-of select="round(xs:double($tint-decl/@TintValue)*100) * 0.0001" />
                  </idml2xml:attribute>
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <!-- standard case if background-color-->
                <xsl:apply-templates select="$tint-decl/@TintValue" mode="#current" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="matches($val, '^Gradient/')">
            <!-- very basic approach. neither the directions nor the angles or positions are taken into consideration.
            stopped mapping of border colors, because it is only allowed as whole border-image, not for border-right etc. Untergliedern, Fragezeichen ist doof-->
            <xsl:variable name="gradient" select="key('idml2xml:gradient', $val, root($val))[1]" as="element(Gradient)?" />
            <xsl:variable name="colorStops0" as="document-node()">
              <xsl:document>
                <xsl:apply-templates select="$gradient/GradientStop/@StopColor" mode="#current">
                  <xsl:sort order="ascending" select="../@Location" data-type="number"/>
                </xsl:apply-templates>  
              </xsl:document>
            </xsl:variable>
            <xsl:variable name="colorStops" as="element(idml2xml:attribute)*">
              <xsl:for-each-group select="$colorStops0/idml2xml:attribute" group-starting-with="*[@name = 'css:background-color']">
                <xsl:if test="current-group()/@name = 'css:background-color'">
                  <xsl:copy>
                    <xsl:copy-of select="@name"/>
                    <!-- question: do we need to subtract fill-tint from 1 to get the CSS saturation percentage? 
                    Or even more complicated stuff? Is device-cmyk expected at all here in regular CSS? -->
                    <xsl:value-of select="string-join(current-group()[@name = ('css:background-color', 'fill-tint')], ' ')"/>
                  </xsl:copy>  
                </xsl:if>
              </xsl:for-each-group>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$target-name = 'css:background-color'">
                <idml2xml:attribute name="{concat(replace($target-name, '-color', ''), '-image')}">
                  <xsl:value-of select="concat(lower-case($gradient/@Type),'-gradient(', string-join($colorStops, ', '), ')')"/>
                </idml2xml:attribute>
              </xsl:when>
              <xsl:otherwise>
                <idml2xml:attribute name="{$target-name}">
                  <xsl:message select="'############## Gradient for illegal attribute:', $target-name, 'used.'"/>
                  <xsl:value-of select="'?'"/>
                </idml2xml:attribute>
              </xsl:otherwise>
            </xsl:choose>
           </xsl:when>
          <!-- no color in any case for FillColor="Swatch/..."? -->
          <xsl:when test="matches($val, ('^Swatch/None|^n$'))">
            <xsl:choose>
              <xsl:when test="matches($target-name, '^css:border-(top|left|right|bottom)-color')">
                <idml2xml:attribute name="{../@target-name}">
                  <xsl:text>transparent</xsl:text>
                </idml2xml:attribute>
              </xsl:when>
              <xsl:otherwise>
                <idml2xml:remove-attribute name="{../@target-name}" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="matches($val, '^Text Color$')">
            <idml2xml:attribute name="{../@target-name}-text-color">
              <xsl:text>true</xsl:text>
            </idml2xml:attribute>
          </xsl:when>
          <xsl:otherwise>
            <idml2xml:attribute name="{../@target-name}">?</idml2xml:attribute>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test=". eq 'condition'">
        <idml2xml:attribute name="remap">HiddenText</idml2xml:attribute>
        <idml2xml:attribute name="condition">
          <xsl:value-of select="replace($val, 'Condition/', '')"/>
        </idml2xml:attribute>
        <xsl:apply-templates select="key('idml2xml:by-Self', tokenize($val, '\s+'), root($val))/@Visible" mode="#current"/>
      </xsl:when>

      <xsl:when test=". eq 'lang'"/>

      <xsl:when test=". eq 'length'">
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="idml2xml:pt-length($val)" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'linear'">
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="$val" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'list-type-declaration'">
        <!-- $val is @BulletsAndNumberingListType -->
        <xsl:choose>
          <xsl:when test="$val = 'NoList'">
            <idml2xml:remove-attribute name="css:list-style-type"/>
            <!--<idml2xml:remove-attribute name="css:display" value="list-item"/>-->
            <idml2xml:attribute name="css:display">block</idml2xml:attribute>
            <idml2xml:attribute name="{name($val)}">NoList</idml2xml:attribute>
          </xsl:when>
          <xsl:when test="$val = 'NumberedList'
                          and
                          $val/../@NumberingExpression = ''">
            <!-- block didn’t work for the inheritance in PFB/85813 -->
<!--            <idml2xml:attribute name="css:display">block</idml2xml:attribute>-->
            <idml2xml:attribute name="css:display">list-item</idml2xml:attribute> 
            <idml2xml:remove-attribute name="css:display" value="list-item"/>
            <idml2xml:attribute name="{name($val)}">
              <xsl:value-of select="$val"/>
            </idml2xml:attribute>
            <idml2xml:attribute name="{../@target-name}">
              <xsl:value-of select="'idml2xml:numbered'"/>
            </idml2xml:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="pstyle-or-p" select="$val/.." as="element(*)"/>
            <idml2xml:attribute name="css:display">list-item</idml2xml:attribute>
            <xsl:choose>
              <xsl:when test="$val = 'BulletList'">
                <idml2xml:attribute name="{../@target-name}">
                  <xsl:value-of select="idml2xml:bullet-list-style-type($pstyle-or-p)"/>
                </idml2xml:attribute>
              </xsl:when>
              <xsl:when test="$val = 'NumberedList'">
                <!-- preliminary -->
                <idml2xml:attribute name="{../@target-name}">
                  <xsl:value-of select="'idml2xml:numbered'"/>
                </idml2xml:attribute>
              </xsl:when>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:when test=". eq 'numbering-family'">
        <idml2xml:attribute name="{../@target-name}">
          <xsl:choose>
            <xsl:when test="$val = 'NumberingList/$ID/[Default]'">
              <xsl:value-of select="''" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="replace($val, '^NumberingList/', '')" />
            </xsl:otherwise>
          </xsl:choose>
        </idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'passthru'">
        <idml2xml:attribute name="{../@name}"><xsl:value-of select="$val" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'percentage'">
        <xsl:if test="$val castable as xs:double and not(number($val) = -1)">
          <idml2xml:attribute name="{../@target-name}">
            <xsl:value-of select="format-number($val*.01, '##0.00###')" />
          </idml2xml:attribute>
        </xsl:if>
      </xsl:when>
      
      <xsl:when test=". eq 'position'">
        <xsl:variable name="script-name" select="lower-case(replace($val, '^OT', ''))" as="xs:string"/>
        <xsl:choose>
          <xsl:when test="$val eq 'Normal'" />
          <xsl:when test="name($val/..) = 'TextDefault'">
            <idml2xml:attribute name="{../@target-name}">
              <xsl:value-of select="replace($script-name, 'script', '')"/>
            </idml2xml:attribute>
          </xsl:when>
          <xsl:otherwise>
            <idml2xml:wrap element="{lower-case(replace($val, '^OT', ''))}" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test=". eq 'style-link'">
        <xsl:choose>
          <xsl:when test="$val = 'n'">
            <idml2xml:no-style-link type="{../@name}"/>
          </xsl:when>
          <xsl:otherwise>
            <idml2xml:style-link type="{../@name}" target="{idml2xml:StyleName($val)}"/>    
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test=". eq 'tablist' and exists($val/*)">
        <tabs xmlns="http://docbook.org/ns/docbook">
          <xsl:apply-templates select="$val/*" mode="#current"/>
        </tabs>
      </xsl:when>
      <xsl:when test=". eq 'tablist' and not(exists($val/*))"/>
      
      <xsl:otherwise>
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="$val" /></idml2xml:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="idml2xml:bullet-list-style-type" as="xs:string">
    <xsl:param name="styled-element" as="element(*)"/><!-- ParagraphStyle, idml2xml:genPara, etc. -->
    <!-- To do: provide the reserved names from http://www.w3.org/TR/css3-lists/#ua-stylesheet for the corresponding chars --> 
    <xsl:variable name="char-elt" select="$styled-element/Properties/BulletChar" as="element(BulletChar)?"/>
    <xsl:variable name="is-unicode" as="xs:boolean"
                  select="$styled-element/Properties/BulletChar/@BulletCharacterType = ('UnicodeOnly', 'UnicodeWithFont')"/>
    <xsl:value-of select="     if(not($char-elt) or ($is-unicode and $char-elt/@BulletCharacterValue = '8226'))
                               then 'disc'
                          else if($is-unicode and $char-elt/@BulletCharacterValue = ('8211', '8212', '8722')) (:U+2013, U+2014, U+2212:)
                               then 'hyphen'
                          else if($is-unicode and $char-elt/@BulletCharacterValue = ('10003'))                (:U+2713:)
                               then 'check'
                          else if($is-unicode and $char-elt/@BulletCharacterValue = ('9702'))                 (:U+25E6:)
                               then 'circle' 
                          else if($is-unicode and $char-elt/@BulletCharacterValue = ('9670'))                 (:U+25C6:)
                               then 'diamond'
                          else if($is-unicode and $char-elt/@BulletCharacterValue = ('9725'))                 (:U+25FD:)
                               then 'box'
                          else if($is-unicode and $char-elt/@BulletCharacterValue = ('9723'))                 (:U+25FB:)
                               then '&#x25fb;'
                          else if($is-unicode and $char-elt/@BulletCharacterValue = ('9726'))                 (:U+25FE:)
                               then 'square'
                          else if($is-unicode and $char-elt/@BulletCharacterValue)
                               then concat('''', codepoints-to-string($char-elt/@BulletCharacterValue), '''')
                          else      concat('''', $styled-element/@BulletChar, '''')"/>
  </xsl:function>
  
  <xsl:function name="idml2xml:generate-css-transform-expression" as="xs:string?" >
    <xsl:param name="atts" as="attribute(*)*"/>
    <xsl:variable name="scaleX" select="$atts[name() = 'css:_transform_scaleX'][last()]/number()" as="xs:double?"/>
    <xsl:variable name="scaleY" select="$atts[name() = 'css:_transform_scaleY'][last()]/number()" as="xs:double?"/>
    <!-- to do: rotate, translate -->
    <xsl:choose>
      <xsl:when test="exists($atts) and (every $a in $atts satisfies (matches(name($a), 'transform_scale[XY]')))">
        <xsl:choose>
          <xsl:when test="$scaleX = $scaleY and ($scaleY = 1)"/>
          <xsl:when test="not($scaleY) and $scaleX = 1"/>
          <xsl:when test="not($scaleX) and $scaleY = 1"/>
          <xsl:when test="$scaleX = $scaleY and ($scaleY != 1)">
            <xsl:sequence select="concat('scale(', $scaleX, ')')"/>
          </xsl:when>
          <xsl:when test="(not($scaleX) or $scaleX = 1) and ($scaleY != 1)">
            <xsl:sequence select="concat('scaleY(', $scaleY, ')')"/>
          </xsl:when>
          <xsl:when test="(not($scaleY) or $scaleY = 1) and ($scaleX != 1)">
            <xsl:sequence select="concat('scaleX(', $scaleX, ')')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="concat('scale(', $scaleX, ', ', $scaleY, ')')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  

  <xsl:function name="idml2xml:pt-length" as="xs:string" >
    <xsl:param name="val" as="xs:string"/>
    <xsl:sequence select="concat(xs:string(xs:integer(xs:double($val) * 20) * 0.05), 'pt')" />
  </xsl:function>

  <xsl:template match="val/@match" mode="idml2xml:XML-Hubformat-add-properties" as="element(*)?">
    <xsl:param name="val" as="node()" tunnel="yes" />
    <xsl:if test="matches($val, .)">
      <xsl:call-template name="idml2xml:XML-Hubformat-atts" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="val/@eq" mode="idml2xml:XML-Hubformat-add-properties" as="element(*)?">
    <xsl:param name="val" as="node()" tunnel="yes" />
    <xsl:if test="$val eq .">
      <xsl:call-template name="idml2xml:XML-Hubformat-atts" />
    </xsl:if>
  </xsl:template>

  <xsl:template name="idml2xml:XML-Hubformat-atts" as="element(*)?">
    <xsl:variable name="target-val" select="(../@target-value, ../../@target-value)[last()]" as="xs:string?" />
    <xsl:if test="exists($target-val)">
      <idml2xml:attribute name="{(../@target-name, ../../@target-name)[last()]}"><xsl:value-of select="$target-val" /></idml2xml:attribute>
    </xsl:if>
  </xsl:template>

  <!-- Multiplier is given only in case of UnderlineColor, I guess. Not sure. -->
  <xsl:template match="Color" mode="idml2xml:XML-Hubformat-add-properties" as="xs:string">
    <xsl:param name="multiplier" as="xs:double" select="1.0" />
    <xsl:choose>
      <xsl:when test="@Space eq 'CMYK'">
        <xsl:sequence select="concat(
                                'device-cmyk(', 
                                string-join(
                                  for $v in tokenize(@ColorValue, '\s') return xs:string(xs:integer(xs:double($v) * 10000 * $multiplier) * 0.000001)
                                  , ','
                                ),
                                ')'
                              )" />
      </xsl:when>
      <xsl:when test="@Space eq 'RGB'">
        <xsl:variable name="vals" select="for $c in tokenize(@ColorValue, '\s+') return number($c)" as="xs:double+"/>
        <xsl:sequence select="idml2xml:tint-dec-rgb-triple($vals, $multiplier)"/>
      </xsl:when>
      <xsl:when test="@Name[starts-with(., 'PANTONE ') and matches(., ' [CU]$')]">
        <xsl:variable name="vals" select="for $c in tokenize(tr:pantone-to-rgb(@Name), '\s+') return number($c)" as="xs:double*"/>
        <xsl:sequence select="if (exists($vals)) then idml2xml:tint-dec-rgb-triple($vals, $multiplier) else @ColorValue"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Unknown colorspace <xsl:value-of select="@Space"/>
        </xsl:message>
        <xsl:sequence select="@ColorValue" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="idml2xml:tint-dec-rgb-triple" as="xs:string">
    <xsl:param name="vals" as="xs:double+"/>
    <xsl:param name="multiplier" as="xs:double"/>
    <xsl:variable name="tinted" select="for $c in $vals return round(255 - (255 - $c) * $multiplier) cast as xs:integer" 
      as="xs:integer+"/>
    <xsl:sequence select="string-join(('#', for $c in $tinted return tr:pad(tr:dec-to-hex($c), 2)), '')"/>
  </xsl:function>

  <xsl:template match="TabList/ListItem" mode="idml2xml:XML-Hubformat-add-properties" as="element(dbk:tab)">
    <tab>
      <xsl:apply-templates mode="#current" />
    </tab>
  </xsl:template>

  <xsl:template match="idPkg:Styles | idPkg:Graphic | idPkg:Preferences/*[not(self::TextDefault)] | idml2xml:hyper | idml2xml:lang | idml2xml:cond 
                     | idml2xml:numbering | idml2xml:endnotes" mode="idml2xml:XML-Hubformat-add-properties" />

  <xsl:template match="PageReference" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:copy-of select="." />
  </xsl:template>

  <xsl:key name="idml2xml:style" 
    match="CellStyle | CharacterStyle | ObjectStyle | ParagraphStyle | TableStyle" 
    use="idml2xml:StyleNameEscape(@Self)" />

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-properties2atts -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  <!-- select most frequently used language (in paragraphs by character count) 
       as the document's default language -->
  
  <xsl:template match="/dbk:hub" mode="idml2xml:XML-Hubformat-extract-frames">
    <xsl:variable name="most-frequent-lang" select="idml2xml:most-frequent-lang(.)" as="xs:string?"/>
    <xsl:copy>
      <xsl:attribute name="xml:lang" select="$most-frequent-lang"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="idml2xml:most-frequent-lang" as="xs:string?">
    <xsl:param name="context" as="element(*)"/>
    <xsl:variable name="langs" as="xs:string*">
      <xsl:for-each-group select="$context//idml2xml:genPara" group-by="idml2xml:text-lang(.)">
        <xsl:sort select="string-length(string-join(current-group()/*, ''))" order="descending"/>
<!--        <xsl:message select="string-length(string-join(current-group()/*, '')), '###### groups:', current-grouping-key(), ' -\-\-\-\-\-\-\-\-\-\-\-\-\- ', count(current-group()), ' ##### ', distinct-values(current-group()/@aid:pstyle)"/>-->
        <xsl:sequence select="current-grouping-key()"/>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:sequence select="$langs[1]"/>
  </xsl:function>
  
  <xsl:function name="idml2xml:text-lang" as="xs:string?">
    <xsl:param name="text" as="element(idml2xml:genPara)"/>
    <xsl:variable name="style-name" select="idml2xml:StyleNameEscape($text/@aid:pstyle)" as="xs:string"/>    
    <xsl:variable name="lang-by-style" select="$text/ancestor::dbk:hub/dbk:info/css:rules/css:rule[@name eq $style-name][@layout-type = 'para']/@xml:lang[last()]" as="attribute(xml:lang)?"/>
    <xsl:variable name="lang-override" select="$text/@xml:lang" as="attribute(xml:lang)?"/>
    <xsl:sequence select="($lang-override, $lang-by-style)[1]"/>
  </xsl:function>

  <xsl:template match="* | @*" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:variable name="atts" as="attribute(*)*">
      <xsl:apply-templates
        select="idml2xml:attribute
                  [not(
                    @name = following-sibling::idml2xml:remove-attribute[if (@name = 'css:display' and @value = 'list-item')
                                                                         then empty(following-sibling::idml2xml:attribute[@name = 'numbering-expression']/text())
                                                                         else true()]
                                                   /@name
                    and
                    (if (@value) then @value = current() else true())
                  )]" mode="#current" />
    </xsl:variable>
    <xsl:variable name="content" as="node()*">
      <xsl:apply-templates select="$atts[not(matches(name(), '^css:_transform'))]" mode="idml2xml:XML-Hubformat-properties2atts-compound" />
      <xsl:variable name="transform-expression" select=" idml2xml:generate-css-transform-expression($atts[matches(name(), '^css:_transform')])" />
      <xsl:if test="$transform-expression">
        <xsl:attribute name="css:transform" select="$transform-expression"/>
      </xsl:if>
      <xsl:apply-templates select="node() except (idml2xml:attribute | idml2xml:wrap | idml2xml:style-link)" mode="#current" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="exists(idml2xml:wrap) and exists(self::dbk:style | self::css:rule)">
        <xsl:copy>
          <xsl:sequence select="@*"/>
          <xsl:attribute name="remap" select="idml2xml:wrap/@element" />
          <xsl:sequence select="$content, processing-instruction()"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="exists(idml2xml:wrap) and empty(self::dbk:style | self::css:rule)">
        <xsl:sequence select="idml2xml:wrap($content, (idml2xml:wrap)), processing-instruction()" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:sequence select="@*, $content, processing-instruction()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- save idml2xml:indexterms for mode XML-Hubformat-cleanup-paras-and-br -->
  <xsl:template match="idml2xml:indexterms" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:sequence select="."/>
  </xsl:template>

  <xsl:template match="@*" mode="idml2xml:XML-Hubformat-properties2atts-compound">
    <xsl:copy/>
  </xsl:template>

  <xsl:function name="idml2xml:wrap" as="node()*">
    <xsl:param name="content" as="node()*" />
    <xsl:param name="wrappers" as="element(idml2xml:wrap)*" />
    <xsl:choose>
      <xsl:when test="exists($wrappers)">
        <xsl:element name="{$wrappers[1]/@element}">
          <xsl:sequence select="idml2xml:wrap($content, $wrappers[position() gt 1])" />
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$content" mode="idml2xml:XML-Hubformat-properties2atts"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="TextWrapPreference | FrameFittingOption | ObjectExportOption | AnchoredObjectSetting"
    mode="idml2xml:XML-Hubformat-properties2atts"/>
  
  <xsl:template match="*[self::*:PDF | self::*:Image][..[*:ObjectExportOption[@CustomAltText ne '$ID/']]]/@Self"  mode="idml2xml:JoinSpans" priority="2">
    <xsl:next-match/>
    <xsl:apply-templates select="../../*:ObjectExportOption/@CustomAltText" mode="#current"/>
  </xsl:template>

  <xsl:template match="idml2xml:attribute" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:choose>
      <xsl:when test="matches(@name, '^\i\c*$')">
        <xsl:attribute name="{@name}" select="." />    
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Cannot create attribute: <xsl:copy-of select="." copy-namespaces="no"/></xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <xsl:key name="idml2xml:css-rule-by-name" match="css:rule" use="@name"/>
  
  <xsl:function name="tr:layout-type-by-idml2xml-attribute" as="xs:string">
    <xsl:param name="attr" as="element(idml2xml:attribute)?"/>
    <xsl:choose>
      <xsl:when test="empty($attr)">
        <xsl:sequence select="'nonex'"/>
      </xsl:when>
      <xsl:when test="$attr/@name eq 'aid:pstyle'">para</xsl:when>
      <xsl:when test="$attr/@name eq 'aid:cstyle'">inline</xsl:when>
      <xsl:when test="matches($attr/@name, '^aid5?:cellstyle$')">cell</xsl:when>
      <xsl:when test="matches($attr/@name, '^aid5?:tablestyle$')">table</xsl:when>
      <xsl:otherwise>object</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="idml2xml:attribute[@name = ('css:background-color', 
                                                   'css:color', 
                                                   'css:border-top-color', 
                                                   'css:border-left-color', 
                                                   'css:border-right-color', 
                                                   'css:border-bottom-color', 
                                                   'css:border-color',
                                                   'idml2xml:StartRowFillColor',
                                                   'idml2xml:EndRowFillColor'
                                                   )]
                                         [$hub-version ne '1.0']" 
    mode="idml2xml:XML-Hubformat-properties2atts">
    <!-- Even if we’re processing local override colors here: 
         a fill tint that comes from a style has to be applied here. 
         If it isn’t superseded by a local override tint, of course. -->
    <xsl:variable name="layout-type" as="xs:string"
      select="(
                ../@layout-type,
                tr:layout-type-by-idml2xml-attribute(../idml2xml:attribute[matches(@name, '^aid5?:(cell|table|[cp])style$')])
              )[1]"/>
    <xsl:variable name="style" select="key('idml2xml:css-rule-by-name', 
                                           ../idml2xml:attribute[matches(@name, '^aid5?:(cell|table|[cp])style$')]
                                          )[@layout-type = $layout-type]"
                  as="element(css:rule)?"/>
    <xsl:variable name="last-fill-tint"  as="element(idml2xml:attribute)?">
      <!-- rules above and below have an own tint attribute which is mapped to border-bottom-tint e.g.. handled separately -->

      <xsl:choose>
        <xsl:when test="@name = 'css:border-top-color'">
          <xsl:sequence select="(($style | ..)/idml2xml:attribute[@name = ('border-top-tint')])[last()]"/>
        </xsl:when>
        <xsl:when test="@name = 'css:border-bottom-color'">
          <xsl:sequence select="(($style | ..)/idml2xml:attribute[@name = ('border-bottom-tint')])[last()]"/>
        </xsl:when>
        <xsl:when test="@name = 'css:border-left-color'">
          <xsl:sequence select="(($style | ..)/idml2xml:attribute[@name = ('border-left-tint')])[last()]"/>
        </xsl:when>
        <xsl:when test="@name = 'css:border-right-color'">
          <xsl:sequence select="(($style | ..)/idml2xml:attribute[@name = ('border-right-tint')])[last()]"/>
        </xsl:when>
        <xsl:when test="@name = 'idml2xml:StartRowFillColor'">
          <xsl:sequence select="(($style | ..)/idml2xml:attribute[@name = ('idml2xml:StartRowFillTint')])[last()]"/>
        </xsl:when>
        <xsl:when test="@name = 'idml2xml:EndRowFillColor'">
          <xsl:sequence select="(($style | ..)/idml2xml:attribute[@name = ('idml2xml:EndRowFillTint')])[last()]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="(
                                  ($style | ..)/idml2xml:attribute[@name = 'fill-tint'], 
                                  ($style | ..)/idml2xml:attribute[@name = 'fill-value'],
                                  ($style | ..)/idml2xml:attribute[@name = 'border-tint']
                                )[last()]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable> 
    <xsl:variable name="tinted" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches(., '^device-cmyk')">
          <xsl:sequence select="idml2xml:tint-color(., (xs:double(tokenize($last-fill-tint, '\s')[1]), 1.0)[1])" />
        </xsl:when>
        <xsl:when test="matches(., '^#[\da-f]{6}$', 'i')">
          <xsl:sequence
            select="idml2xml:tint-dec-rgb-triple(
                                for $i in (tr:rgb-string-to-dec-triple(.)) return number($i), 
                                ($last-fill-tint, 1.0)[1]
                              )"
            />
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>Cannot tint <xsl:value-of select="."/></xsl:message>
          <xsl:sequence select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="@name = 'css:color'">
      <!-- border color = text color handling -->
      <xsl:variable name="context" as="element(idml2xml:attribute)" select="."/>
      <xsl:for-each select="('css:border-top-color', 'css:border-bottom-color')">
        <xsl:variable name="propname" as="xs:string" select="."/>
        <xsl:variable name="msa" as="element(idml2xml:attribute)?"
          select="($context/../idml2xml:attribute[@name = ($propname, concat($propname, '-text-color'))])[1]"/>
        <xsl:if test="$msa/@name = concat($propname, '-text-color')">
          <xsl:attribute name="{$propname}" select="$tinted"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
    <xsl:attribute name="{@name}" select="$tinted" />
  </xsl:template>
  
  <xsl:template 
    match="idml2xml:attribute[@name = ('css:border-top-color', 'css:border-bottom-color')]
                             [following-sibling::idml2xml:attribute[
                               @name = concat(
                                         current()/@name, 
                                         '-text-color'
                                       )
                             ]]" 
    mode="idml2xml:XML-Hubformat-properties2atts" priority="2">
    <!-- If there is a following css:border-top-color-text-color, do nothing
    (will be handled by css:color) -->
  </xsl:template>
  
  <xsl:template match="idml2xml:attribute[@name = ('fill-tint','fill-value', 'css:border-top-color-text-color', 'css:border-bottom-color-text-color', 'css:text-decoration-color-text-color', 'border-tint', 'border-left-tint', 'border-right-tint','border-top-tint', 'border-bottom-tint')]" mode="idml2xml:XML-Hubformat-properties2atts"/>
  <xsl:template match="idml2xml:attribute[@name = 'css:border-top-left-radius'][following-sibling::idml2xml:attribute[@name = ('idml2xml:TopLeftCornerOption', 'idml2xml:CornerOption')][. = 'None']]" mode="idml2xml:XML-Hubformat-properties2atts"/>
  <xsl:template match="idml2xml:attribute[@name = 'css:border-top-right-radius'][following-sibling::idml2xml:attribute[@name = ('idml2xml:TopRightCornerOption', 'idml2xml:CornerOption')][. = 'None']]" mode="idml2xml:XML-Hubformat-properties2atts"/>
  <xsl:template match="idml2xml:attribute[@name = 'css:border-bottom-left-radius'][following-sibling::idml2xml:attribute[@name = ('idml2xml:BottomLeftCornerOption', 'idml2xml:CornerOption')][. = 'None']]" mode="idml2xml:XML-Hubformat-properties2atts"/>
  <xsl:template match="idml2xml:attribute[@name = 'css:border-bottom-right-radius'][following-sibling::idml2xml:attribute[@name = ('idml2xml:BottomRightCornerOption', 'idml2xml:CornerOption')][. = 'None']]" mode="idml2xml:XML-Hubformat-properties2atts"/>
	<xsl:template match="idml2xml:attribute[matches(@name, 'css:border(-(top|left|right|bottom))?-(width|color|style)')][following-sibling::idml2xml:attribute[@name = 'idml2xml:EnableStrokeAndCornerOptions'][. = 'false']]" mode="idml2xml:XML-Hubformat-properties2atts" priority="5"/>

  <xsl:template match="idml2xml:attribute[matches(@name, '^css:pseudo-marker')]" mode="idml2xml:XML-Hubformat-properties2atts">
    <!-- list-type: Hub 1.0 -->
    <xsl:variable name="last-numbering-style" as="element(idml2xml:attribute)?"
      select="../idml2xml:attribute[@name = ('BulletsAndNumberingListType', 'list-type', 'css:list-style-type')][last()]" />
    <xsl:choose>
      <xsl:when test="$last-numbering-style = 'NoList'"/>
      <xsl:when test="$last-numbering-style = 'idml2xml:numbered'"/>
      <xsl:when test="@name = 'css:pseudo-marker_font-family' and . = '$ID/'"/>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template
    match="idml2xml:attribute[@name eq 'css:list-style-type']
                             [. is ../idml2xml:attribute[@name = ('BulletsAndNumberingListType', 'list-type', 'css:list-style-type')][last()]]
                             [. = 'idml2xml:numbered']"
    mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:variable name="style" as="element(css:rule)?"
      select="if (exists(parent::css:rule)) then ()
              else key(
                'idml2xml:css-rule-by-name', 
                idml2xml:StyleNameEscape(
                  ../idml2xml:attribute[@name eq 'aid:pstyle']
                )
              )"/>
    <xsl:attribute name="css:list-style-type" select="idml2xml:numbered-list-style-type(
                                                        (($style, ..)/idml2xml:attribute[@name eq 'numbering-format'])[last()],
                                                        (($style, ..)/idml2xml:attribute[@name eq 'numbering-expression'])[last()],
                                                        (($style, ..)/idml2xml:attribute[@name eq 'numbering-level'])[last()]
                                                      )"/>
    <xsl:attribute name="hub:numbering-picture-string" select="(($style, ..)/idml2xml:attribute[@name eq 'numbering-expression'])[last()]"/>
    <xsl:if test="not(../idml2xml:attribute[@name eq 'numbering-starts-at'][last()] = '1')">
      <xsl:attribute name="hub:numbering-starts-at" select="(($style, ..)/idml2xml:attribute[@name eq 'numbering-starts-at'])[last()]"/>
    </xsl:if>
    <xsl:attribute name="hub:numbering-level" select="(($style, ..)/idml2xml:attribute[@name eq 'numbering-level'])[last()]"/>
    <xsl:if test="../idml2xml:attribute[@name eq 'numbering-continue'][last()] = 'true'">
      <xsl:attribute name="hub:numbering-continue" select="(($style, ..)/idml2xml:attribute[@name eq 'numbering-continue'])[last()]"/>
    </xsl:if>
    <xsl:if test="../idml2xml:attribute[@name eq 'numbering-inline-stylename'][. ne 'CharacterStyle/$ID/[No character style]']">
      <xsl:attribute name="hub:numbering-inline-stylename" select="idml2xml:StyleName((../idml2xml:attribute[@name eq 'numbering-inline-stylename'])[last()])"/>
    </xsl:if>
  	<!--<xsl:if test="../idml2xml:attribute[@name eq 'restart-at-higher-level'][. ne 'true'][(($style, ..)/idml2xml:attribute[@name eq 'numbering-level'])[last()] ne '1']">
      <xsl:attribute name="hub:restart-at-higher-level" select="(($style, ..)/idml2xml:attribute[@name eq 'restart-at-higher-level'])[last()]"/>
    </xsl:if>-->
  </xsl:template>
  
  <xsl:template
    match="idml2xml:genPara/idml2xml:attribute[@name = ('numbering-continue', 'numbering-starts-at', 'restart-at-higher-level')]" mode="idml2xml:XML-Hubformat-properties2atts" priority="4">
    <xsl:attribute name="{concat('hub:', @name)}" select="."/>
  </xsl:template>
	
  <xsl:template mode="idml2xml:XML-Hubformat-properties2atts_DISABLED" priority="2" 
    match="idml2xml:attribute[@name = ('numbering-starts-at', 'numbering-format', 'numbering-expression', 'restart-at-higher-level', 'numbering-continue', 'numbering-level', 'numbering-inline-stylename')]" />
  
  <xsl:function name="idml2xml:numbered-list-style-type" as="xs:string">
    <xsl:param name="type-example-string" as="xs:string?"/>
    <xsl:param name="picture-string" as="xs:string?"/>
    <xsl:param name="level" as="xs:string?"/>
    <!-- §§§ Please note that the picture string does not influence the result.
         This is partly due do CSS3 lists not supporting interpunction and
         inclusion of upper levels in a straightforward declarative way -->
    <xsl:choose>
      <xsl:when test="empty($type-example-string) or empty($picture-string) or empty($level)">
        <!-- this should not happen. It happened once when a style name contained U+000D that
          was converted differently for ParagraphStyle/@Self (hex-encoded) and ParagraphStyle/@Name (Unicode)
          so that the css:rule could not be found. With tr:unescape-uri, it should be fixed. -->
        <xsl:sequence select="'underspecified'"/>
      </xsl:when>
      <xsl:when test="matches($type-example-string, '^0*1')">
        <xsl:sequence select="'decimal'"/>
      </xsl:when>
      <xsl:when test="starts-with($type-example-string, 'a')">
        <xsl:sequence select="'lower-alpha'"/>
      </xsl:when>
      <xsl:when test="starts-with($type-example-string, 'A')">
        <xsl:sequence select="'upper-alpha'"/>
      </xsl:when>
      <xsl:when test="starts-with($type-example-string, 'i')">
        <xsl:sequence select="'lower-roman'"/>
      </xsl:when>
      <xsl:when test="starts-with($type-example-string, 'I')">
        <xsl:sequence select="'upper-roman'"/>
      </xsl:when>
      <xsl:when test="starts-with($type-example-string, 'None')">
        <xsl:sequence select="'none'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="string-join(($type-example-string, $picture-string), '__')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- As style (will be dealt with when processing other attributes -->
  <xsl:template match="css:rule/idml2xml:attribute[@name = 'BulletsAndNumberingListType']" 
    priority="2" mode="idml2xml:XML-Hubformat-properties2atts"/>
  
  <!-- As local override: -->
  <xsl:template match="idml2xml:attribute[@name = 'BulletsAndNumberingListType'][. = 'NoList']" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:attribute name="css:display" select="'block'"/>
  </xsl:template>
  
  <xsl:template match="idml2xml:attribute[@name = 'css:text-decoration-line']" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:variable name="all-atts" select="preceding-sibling::idml2xml:attribute[@name = current()/@name], ."
      as="element(idml2xml:attribute)+"/>
    <xsl:variable name="tokenized" select="for $a in $all-atts return tokenize($a, '\s+')" as="xs:string+"/>
    <xsl:variable name="line-through" select="$tokenized[starts-with(., 'line-through')][last()]"/>
    <xsl:variable name="underline" select="$tokenized[starts-with(., 'underline')][last()]"/>
    <xsl:choose>
      <xsl:when test="every $t in ($line-through, $underline) satisfies (ends-with($t, 'none'))">
        <xsl:attribute name="{@name}" select="'none'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="{@name}" select="($line-through, $underline)[not(ends-with(., 'none'))]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- aimed at cmyk colors in the 0.0 .. 1.0 value space -->
  <xsl:function name="idml2xml:tint-color" as="xs:string">
    <xsl:param name="color" as="xs:string" />
    <xsl:param name="tint" as="xs:double" />
    <xsl:variable name="positive-tint" as="xs:double" select="if ($tint lt 0) then 1 else $tint" />
    <xsl:variable name="tmp" as="xs:string+">
      <xsl:analyze-string select="$color" regex="[0-9.]+">
        <xsl:matching-substring>
          <xsl:sequence select="xs:string(xs:integer(xs:double(.) * $positive-tint * 100000) * 0.00001)" />
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="." />
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($tmp, '')" />
  </xsl:function>

  <xsl:template match="idml2xml:remove-attribute | idml2xml:no-style-link" mode="idml2xml:XML-Hubformat-properties2atts" />

  <xsl:template match="idml2xml:style-link" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:choose>
      <xsl:when test="$hub-version eq '1.0'">
        <xsl:attribute name="{if (@type eq 'AppliedParagraphStyle')
                              then 'parastyle'
                              else @type}" 
          select="@target" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="linked-style">
          <xsl:attribute name="layout-type" select="if (@type eq 'AppliedParagraphStyle')
                                                    then 'para'
                                                    else @type" />
          <xsl:attribute name="name" select="idml2xml:StyleName(@target)"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- workaround: how to handle this in ConsolidateParagraphStyleRanges?
       must be solved in GenerateTagging-mode? grep for 'AppliedParagraphStyleCount' -->
  <xsl:template match="idml2xml:ParagraphStyleRange[
                         count(*[not(local-name()=('style-link','attribute'))]) eq 
                         count(idml2xml:genPara)]" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  <xsl:template match="idml2xml:ParagraphStyleRange[
                         count(*[not(local-name()=('style-link','attribute'))]) eq 
                         count(idml2xml:genPara)]/*[local-name()=('style-link','attribute')]" 
                mode="idml2xml:XML-Hubformat-properties2atts" />

  <xsl:template match="dbk:tabs[following-sibling::dbk:tabs]" mode="idml2xml:XML-Hubformat-properties2atts"/>
  
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-extract-frames -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="*[@aid:pstyle]
                        [.//idml2xml:genFrame[idml2xml:same-scope(., current())]]" 
                mode="idml2xml:XML-Hubformat-extract-frames">
    <xsl:variable name="frames" as="element(idml2xml:genFrame)+" 
      select=".//idml2xml:genFrame[idml2xml:same-scope(., current())]"/>
    <xsl:variable name="frames-after-text" select="$frames[not(idml2xml:text-after(., current()))]" 
      as="element(idml2xml:genFrame)*" />
    <xsl:apply-templates select="$frames except $frames-after-text"  mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
    <xsl:apply-templates select="$frames-after-text"  mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
  </xsl:template>

  <xsl:template match="/*/idml2xml:genFrame (: unanchored frames :)" mode="idml2xml:XML-Hubformat-extract-frames">
    <!-- Not sure whether the following commented-out apply-templates is still needed for some IDML files.
      In the case of Campus/ap/51120, a frame that contains a table with the text "company is fixed. When the" was 
      duplicated because 2 genFrames were converted by this apply-templates, but the second of which was converted
      again as part of the first. Therefore I (GI, 2019-08-21) replaced this template with the identity template. --> 
      <!--<xsl:apply-templates select="descendant-or-self::idml2xml:genFrame[idml2xml:same-scope(., current())]"  
                         mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>-->
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="idml2xml:text-after" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:param name="ancestor" as="element(*)" />
    <xsl:sequence select="matches(
                            string-join(
                              $ancestor//text()[. &gt;&gt; $elt][parent::node()[not(matches(@condition, 'Page(Start|End)'))]] 
                              except $ancestor//idml2xml:genFrame//text(),
                              ''
                            ),
                            '\S'
                          )" />
  </xsl:function>

  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames">
    <idml2xml:genAnchor xml:id="{generate-id()}"/>    
  </xsl:template>

  <!-- Frames in Groups that are anchored in inline text. These groups don’t have a child
       with an @aid:pstyle. Therefore, the genFrame extraction template above (first in mode)
       doesn’t match. But the immediately preceding template would match indeed, effectively
       throwing away the figure caption in case of Hogrefe 101026_02142_FPT Abbildung 1. §§§ Create a test case 
  
      GI 2015-11-23: This template led to duplicated content in Klett WIV/input/2015-10-22/DO01800021_S008_S019_01_Unit.idml
      The output was ok without this template. If this change is incompatible with 101026_02142_FPT, we need to adapt
      the matching patterns.

      Tested 101026_02142_FPT with this change. Ok. Content probably not thrown away any more because
      Groups will be carried along in ExtractTagging
  -->
  <xsl:template match="idml2xml:genFrame[ancestor::idml2xml:genFrame[@idml2xml:elementName eq 'Group'][*/@aid:cstyle]]" 
                mode="idml2xml:XML-Hubformat-extract-frames" priority="1">
    <idml2xml:genAnchor xml:id="{generate-id()}"/>
    <xsl:apply-templates select="." mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
  </xsl:template>
  
  <xsl:template match="idml2xml:genFrame[@idml2xml:elementName = 'TextFrame']
                                        [parent::idml2xml:genFrame[@idml2xml:elementName eq 'Group']]" 
                mode="idml2xml:XML-Hubformat-extract-frames">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Keep TextFrames in idml2app/Federal_Maritime_and_Hydrographic_Agency_313006_1_En/M_2_012.idml
    that were lost due to commit #888 (c808eb7). This is a quick fix just minutes ahead of the nightly tests… -->
  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames-genFrame">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="linkend" select="generate-id()" />
      <xsl:apply-templates mode="idml2xml:XML-Hubformat-extract-frames" />
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="idml2xml:XML-Hubformat-extract-frames-genFrame idml2xml:XML-Hubformat-extract-frames" priority="3"
    match="idml2xml:genFrame[not(node())]" />

  <xsl:template match="idml2xml:genSpan[*[name() = $idml2xml:shape-element-names]]
                                       [text()[matches(., '\S')]]"
                mode="idml2xml:XML-Hubformat-extract-frames" priority="3">
    <!-- wasn't handled yet. may occur after anchorings. not sure whether those elements should be pulled out earlier.
          example: Hogrefe PPP 02384 -->
    <!-- MP: I replaced the for-each-group. In chb/bw/69891 it produced wrong results. there was an image between two textnodes. the text was grouped together, the image placed afterwards.-->
    <xsl:variable name="context" select="." as="element(*)"/>
    <xsl:variable name="nodes" select="text(), node()[name() = $idml2xml:shape-element-names][not($context/@remap eq 'HiddenText')]" as="node()*"/>
    <xsl:for-each select="node()">
      <xsl:variable name="pos" select="position()" as="xs:integer"/>
      <xsl:choose>
        <xsl:when test="current() = $idml2xml:shape-element-names and not($context/@remap eq 'HiddenText')">
          <xsl:apply-templates select="." mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <idml2xml:genSpan>
            <xsl:apply-templates select="$context/@*" mode="#current"/>
            <xsl:if test="count($nodes) gt 1">
              <xsl:attribute name="srcpath" select="string-join(($context/@srcpath, string($pos)), ';n=')"/>
            </xsl:if>
            <xsl:apply-templates select="." mode="#current"/>
          </idml2xml:genSpan>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-remap-para-and-span -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="/*" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:next-match>
      <xsl:with-param name="text-default" as="element(TextDefault)" tunnel="yes" select="idPkg:Preferences/TextDefault"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:variable name="id-prefix" select="'id_'" as="xs:string"/>

  <xsl:template match="idml2xml:genPara" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="role" as="xs:string?" select="for $s in @aid:pstyle return idml2xml:StyleName(@aid:pstyle)"/>
    <xsl:variable name="css-rule" select="key('idml2xml:css-rule-by-name', $role)[@layout-type = 'para']" 
      as="element(css:rule)"/>
    <xsl:element name="para">
      <xsl:if test="@aid:pstyle">
	      <xsl:attribute name="role" select="$role" />
        <xsl:attribute name="idml2xml:layout-type" select="'para'"/>
      </xsl:if>
      <xsl:call-template name="idml2xml:list-aux-counter-atts">
        <xsl:with-param name="role" select="$role"/>
      </xsl:call-template>
      <xsl:if test="$css-rule/@hub:same-para-style-spacing">
        <xsl:call-template name="idml2xml:same-para-spacing">
          <xsl:with-param name="role" select="$role" as="xs:string?"/>
          <xsl:with-param name="css-rule" select="$css-rule" as="element(css:rule)"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:apply-templates select="@* except @aid:pstyle" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <!-- ID same-para-spacing overrides vertical margins for paragraphs of the same style -->
  
  <xsl:template name="idml2xml:same-para-spacing">
    <xsl:param name="role" as="xs:string?"/>
    <xsl:param name="css-rule" as="element(css:rule)"/>
    <xsl:variable name="context" select="." as="element(idml2xml:genPara)"/>
    <xsl:variable name="next-para" select="$context/following-sibling::*[2][self::idml2xml:genPara]" as="element(idml2xml:genPara)?"/>
    <xsl:if test="for $s in $next-para/@aid:pstyle return idml2xml:StyleName($next-para/@aid:pstyle) = $role">
      <xsl:attribute name="css:margin-bottom" select="$css-rule/@hub:same-para-style-spacing"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:key name="idml2xml:paras-by-numbering-family" match="idml2xml:genPara" 
    use="idml2xml:numbering-family-for-para(.)"/>

  <xsl:function name="idml2xml:numbering-family-for-para" as="xs:string?">
    <xsl:param name="para" as="element(idml2xml:genPara)"/>
    <xsl:variable name="pstyle" as="element(css:rule)*" 
      select="if (normalize-space($para/@aid:pstyle)) 
              then key('idml2xml:style-by-role', idml2xml:StyleName($para/@aid:pstyle), root($para))
              else ()"/>
    <xsl:if test="(:($pstyle/@css:display, $para/@css:display)[last()] = 'list-item'
                  and :) (: we need to drop this condition since there may be deactivated lists,
                  https://redmine.le-tex.de/issues/5887 :)
                  exists(($pstyle/@hub:numbering-level, $para/@hub:numbering-level))">
      <xsl:sequence select="for $f in ($pstyle/@hub:numbering-family, $para/@hub:numbering-family)[last()]
                            return string($f)"/>
    </xsl:if>
  </xsl:function>

  <!-- Add auxiliary attributes that will facilitate list number calculations in the next pass: -->
  <xsl:template name="idml2xml:list-aux-counter-atts">
    <!-- context: idml2xml:genPara -->
    <xsl:param name="role" as="xs:string?"/>
    <xsl:param name="text-default" as="element(TextDefault)?" tunnel="yes"/>
    <xsl:variable name="pstyle" as="element(css:rule)*" select="(key('idml2xml:style-by-role', $role))[1]"/>
    <xsl:variable name="numfam" as="xs:string?"
      select="($pstyle/@hub:numbering-family, @hub:numbering-family)[last()]"/>
    <xsl:variable name="numlvl" as="xs:integer?"
      select="for $lvl in ($pstyle/@*:numbering-level, @*:numbering-level)[last()]
              return xs:integer($lvl)"/>
    <xsl:variable name="all-list-styles" as="xs:string*" 
      select="key('idml2xml:list-styles', $numbered-list-styles)[@*:numbering-level = $numlvl]
                                                                [@hub:numbering-family = $numfam]/@name"/>
    <xsl:variable name="picture-string" as="xs:string?"
      select="($pstyle/@hub:numbering-picture-string, @hub:numbering-picture-string)[last()]"/>
    <xsl:if test="($pstyle/@css:display, @css:display)[last()] = 'list-item' (: idml2xml:StyleName(@aid:pstyle) = $all-list-styles :)">
      <xsl:if test="$numlvl">
        <xsl:attribute name="idml2xml:aux-list-level" select="$numlvl"/>
      </xsl:if>
      <xsl:variable name="preceding-same-family" as="element(idml2xml:genPara)*" 
        select="key('idml2xml:paras-by-numbering-family', $numfam)[. &lt;&lt; current()]"/>
      <xsl:variable name="preceding-higher" as="element(idml2xml:genPara)*" 
        select="$preceding-same-family[(if (@aid:pstyle)
                                        then key('idml2xml:style-by-role', idml2xml:StyleName(@aid:pstyle))/@*:numbering-level 
                                        else (),
                                        @*:numbering-level)[last()]
                                       &lt; $numlvl]"/>
      <xsl:variable name="preceding-same" as="element(idml2xml:genPara)*"
        select="$preceding-same-family[(if (@aid:pstyle)
                                        then key('idml2xml:style-by-role', idml2xml:StyleName(@aid:pstyle))/@*:numbering-level 
                                        else (),
                                        @*:numbering-level)[last()]
                                       = $numlvl]"/>
      <!-- reminder: higher level means lower level number -->
      <xsl:variable name="restart-at-higher-level" as="xs:boolean"
        select="($pstyle/@hub:restart-at-higher-level, @hub:restart-at-higher-level)[last()] = 'true'"/>
      <xsl:variable name="continue" as="xs:boolean"
        select="($text-default/@hub:numbering-continue, $pstyle/@hub:numbering-continue, @hub:numbering-continue)[last()] = 'true'"/>
      <xsl:variable name="restart" as="xs:boolean"
        select="empty($preceding-same[
                        (
                          key('idml2xml:style-by-role', idml2xml:StyleName(@aid:pstyle))/@css:display,
                          @css:display
                        )[last()] = 'list-item'
                      ] (: consider only preceding same-family items that actually use a generated numbered list marker.
                            Counterexample: Campus/ap/50452, list after 'A firm, of any size, is a family business, if' :)
                     ) (: not actually restarted by higher level, but still… :)
                or 
                (
                  if ($restart-at-higher-level)
                  then 
                    if ($preceding-same)
                    then ($preceding-higher[last()] &gt;&gt; $preceding-same[last()])
                    else exists($preceding-higher)
                  else false()
                )
                or 
                not($continue)"/>
      <!--<xsl:if test="contains(@srcpath, '[837]')">
        <xsl:message select="'SSSSSSSSSSSSSS ', count($preceding-same-family), count($preceding-same), $restart, $preceding-same"></xsl:message>
      </xsl:if>-->
      <xsl:if test="$restart">
        <xsl:attribute name="idml2xml:aux-list-restart" select="'true'"/>
      </xsl:if>
      <xsl:attribute name="idml2xml:aux-list-famlvl" select="string-join(($numfam, string($numlvl)), '__')"/>
      <xsl:attribute name="idml2xml:aux-list-fam" select="$numfam"/>
      <xsl:attribute name="idml2xml:aux-list-picture-string" select="$picture-string"/>
    </xsl:if>
    
  </xsl:template>

  <!-- Dissolves what was an anchored Group that contains a Rectangle and a TextFrame.
  Example: chb HC 66246 -->
  <xsl:template match="idml2xml:genSpan[*]
                                       [not(text()[matches(., '\S')])]
                                       [
                                         every $c in * satisfies (
                                           exists($c/(self::idml2xml:genFrame | self::idml2xml:genAnchor))
                                         )
                                       ]
                                       [
                                         not(@remap = 'HiddenText')
                                       ]" 
                mode="idml2xml:XML-Hubformat-remap-para-and-span"
                priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- https://redmine.le-tex.de/issues/1237 -->
  <!-- AS: modified to match any span with HiddenText that contains anchor -->
  <xsl:template match="idml2xml:genSpan[*]
                                       [
                                         every $c in * satisfies (
                                           exists($c/(self::idml2xml:genFrame | self::idml2xml:genAnchor))
                                         )
                                       ]
                                       [
                                         @remap = 'HiddenText'
                                       ]" 
                mode="idml2xml:XML-Hubformat-remap-para-and-span"
                priority="2">
    <xsl:element name="phrase">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="idml2xml:genSpan[
                         not(
                           (
                             exists(*[name() = $idml2xml:shape-element-names])
                             or
                             exists(idml2xml:genFrame)
                           ) 
                           or 
                           @aid:table = ('table')
                         ) or
                         (exists(Rectangle) and @condition)
                       ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="role" select="idml2xml:StyleName( (@aid:cstyle, '')[1] )"/>
    <xsl:choose>
      <xsl:when test="$role eq 'No character style' 
                      and not(@condition) 
                      and not(text()[matches(., '\S')]) 
                      and count(*) gt 0 and 
                      count(*) eq count(PageReference union HyperlinkTextSource union idml2xml:tab)">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:when test="$role eq 'No character style' 
                      and not(@condition) 
                      and not(text()[matches(., '\S')]) 
                      and count(* except idml2xml:genAnchor) eq 0">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:when test="$role eq 'No character style' 
                      and text() 
                      and not(@condition) 
                      and count(* except idml2xml:genAnchor) eq 0
                      and count(@* except (@aid:cstyle union @srcpath union @idml2xml:*)) eq 0
                      ">
        <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="atts" select="@* except (@srcpath union @idml2xml:*)" as="attribute(*)*" />
        <xsl:if test="idml2xml:genAnchor">
          <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$atts or @srcpath">
            <phrase>
              <xsl:if test="not($role = ('', 'No character style'))">
                <xsl:attribute name="role" select="$role"/>
                <xsl:attribute name="idml2xml:layout-type" select="'inline'"/>
              </xsl:if>
              <xsl:apply-templates select="@srcpath, $atts except @aid:cstyle, node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
            </phrase>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="idml2xml:link" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:choose>
      <xsl:when test="matches(@idml2xml:href,'(end)?page')">
        <anchor xml:id="{@idml2xml:href}" />
      </xsl:when>
      <xsl:when test="@remap='ExternalHyperlinkTextDestination'">
        <link xlink:href="{@linkend}" role="same-work-external">
          <xsl:apply-templates select="@* except @linkend" mode="#current" />
          <xsl:apply-templates select="node()" mode="#current" />
        </link>
      </xsl:when>
      <xsl:otherwise>
        <link>
          <xsl:apply-templates select="@idml2xml:*, @* | node()" mode="#current" />
        </link>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template match="idml2xml:xref" mode="idml2xml:XML-Hubformat-remap-para-and-span_DISABLED">
    <link>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </link>
  </xsl:template>

  <xsl:function name="idml2xml:normalize-name" as="xs:string">
    <xsl:param name="input" as="xs:string" />
    <xsl:sequence select="replace($input, '\C', '')"/>
  </xsl:function>

  <xsl:template match="idml2xml:genAnchor" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor xml:id="{$id-prefix}{idml2xml:normalize-name(@*:id)}" >
      <xsl:apply-templates select="@annotations" mode="#current"/>
    </anchor>
  </xsl:template>

  <xsl:template match="@linkend[empty(parent::see | parent::seealso | parent::dbk:see | parent::dbk:seealso)]" 
    mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="linkend" select="concat ($id-prefix, idml2xml:normalize-name(.))" />
  </xsl:template>
  
  <xsl:template match="@aid:cstyle" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="role" select="." />
    <xsl:attribute name="idml2xml:layout-type" select="'inline'"/>
  </xsl:template>

  <xsl:template match="idml2xml:genFrame" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <sidebar remap="{@idml2xml:elementName}">
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </sidebar>
  </xsl:template>

  <xsl:template match="@idml2xml:objectstyle" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="role" select="idml2xml:StyleName(.)"/>
    <xsl:attribute name="idml2xml:layout-type" select="'object'"/>
  </xsl:template>

   <xsl:template match="@idml2xml:layer" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="idml2xml:layer" select="."/>
  </xsl:template>
  
  <xsl:template match="@idml2xml:label" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="idml2xml:label" select="."/>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[ not( descendant::node()[self::text()] ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"
		priority="-1">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="/" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:next-match>
      <xsl:with-param name="page-starts" as="element(*)*" tunnel="yes" 
        select="(//HiddenText[(.//@condition)[1] = 'PageStart'], //Note[matches(.//idml2xml:genPara, 'CellPage|PageStart')])[1]"/>
      <xsl:with-param name="page-ends" as="element(*)*" tunnel="yes" 
        select="(//HiddenText[(.//@condition)[1] = 'PageEnd'], //Note[matches(.//idml2xml:genPara, 'PageEnd')])[1]"/>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:key name="idml2xml:hidden-text" match="HiddenText" use="normalize-space(.)"/>
  
  <xsl:key name="idml2xml:note" match="Note" use="normalize-space(.)"/>

  <xsl:template match="HiddenText[(.//@condition)[1] = 'PageStart']" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:param name="page-starts" as="element(HiddenText)*" tunnel="yes"/>
    <xsl:variable name="content" as="xs:string" select="normalize-space(.)"/>
    <xsl:variable name="pos" as="xs:integer" 
      select="idml2xml:index-of(key('idml2xml:hidden-text', $content), .)"/>
    <anchor xml:id="{string-join((
                        if (starts-with($content, 'CellPage')) then 'cellpage' else 'page',
                        replace(., '^.*_(.+)$', '$1'), 
                        for $p in $pos[. gt 1] return string($p)),
                      '_')}"/>
  </xsl:template>
  
  <xsl:template match="Note[matches(.//idml2xml:genPara, 'PageStart|CellPage')]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:param name="page-starts" as="element(Note)*" tunnel="yes"/>
    <xsl:variable name="content" as="xs:string" select="normalize-space(.)"/>
    <xsl:variable name="pos" as="xs:integer" 
      select="idml2xml:index-of(key('idml2xml:note', $content), .)"/>
    <anchor xml:id="{string-join((
      if (starts-with($content, 'CellPage')) then 'cellpage' else 'page',
      replace(., '^.*_(.+)$', '$1'), 
      for $p in $pos[. gt 1] return string($p)),
      '_')}"/>
  </xsl:template>

  <xsl:template match="HiddenText[(.//@condition)[1] = 'PageEnd']" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:param name="page-ends" as="element(HiddenText)*" tunnel="yes"/>
    <xsl:variable name="content" as="xs:string" select="normalize-space(.)"/>
    <xsl:variable name="pos" as="xs:integer" 
      select="idml2xml:index-of(key('idml2xml:hidden-text', $content), .)"/>
    <anchor xml:id="{string-join((replace(., '^.*_(.+)$', 'pageend_$1'), for $p in $pos[. gt 1] return string($p)), '_')}"/>
  </xsl:template>
  
  <xsl:template match="Note[matches(.//idml2xml:genPara, 'PageEnd')]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:param name="page-ends" as="element(Note)*" tunnel="yes"/>
    <xsl:variable name="content" as="xs:string" select="normalize-space(.)"/>
    <xsl:variable name="pos" as="xs:integer" 
      select="idml2xml:index-of(key('idml2xml:note', $content), .)"/>
    <anchor xml:id="{string-join((replace(., '^.*_(.+)$', 'pageend_$1'), for $p in $pos[. gt 1] return string($p)), '_')}"/>
  </xsl:template>

  <xsl:template match="idml2xml:genPara[count(node()) eq 1 and *:HiddenText]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
      <xsl:apply-templates select="node()" mode="#current" />
  </xsl:template>

  <xsl:template match="*:HiddenText" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <sidebar remap="HiddenText">
      <xsl:apply-templates select=".//@condition" mode="#current"/>
      <xsl:if test="$hub-version eq '1.1'">
        <xsl:attribute name="css:display" select="'none'"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </sidebar>
  </xsl:template>

  <xsl:template match="*:HiddenText[
                      not(.//@condition) and 
                         count(node()) eq 1 and 
                         idml2xml:genPara[not(node())]
                       ] |
                       *:HiddenText[not(node())]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span" />
  
  <xsl:template match="idml2xml:parsep"
    mode="idml2xml:XML-Hubformat-remap-para-and-span" />

  <xsl:template match="idml2xml:tab" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <tab>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </tab>
  </xsl:template>
  
  <xsl:template match="idml2xml:control"
    mode="idml2xml:XML-Hubformat-remap-para-and-span" >
    <phrase remap="idml2xml:control">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </phrase>
  </xsl:template>

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
                         preceding-sibling::*[1][self::idml2xml:parsep] and
                         following-sibling::*[1][self::idml2xml:parsep]
                       ]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:element name="para">
      <xsl:attribute 
          name="role" 
          select="if (preceding::*[self::idml2xml:genPara])
                  then preceding::*[self::idml2xml:genPara][1]/@aid:pstyle
                  else following::*[self::idml2xml:genPara][1]/@aid:pstyle"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="idml2xml:ParagraphStyleRange[
                       count(*) eq 1 and idml2xml:genPara
                       ]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template 
    match="@idml2xml:* | idPkg:Preferences" 
    mode="idml2xml:XML-Hubformat-remap-para-and-span" 
    />

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-remap-para-and-span" >
    <xsl:copy-of select="." />
  </xsl:template>

  <!-- Apply default cell style (which is solid, black, 0.5pt) -->
  <xsl:template match="dbk:style[parent::dbk:cellstyles] | css:rule[@layout-type eq 'cell']"
    mode="idml2xml:XML-Hubformat-remap-para-and-span" >
    <xsl:variable name="context" select="." as="element(*)"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each select="('top', 'right', 'bottom', 'left')">
        <xsl:variable name="direction" select="." as="xs:string"/>
        <xsl:for-each select="('color', 'width', 'style')">
          <xsl:variable name="attname" select="concat('css:border-', $direction, '-', .)"/>
          <xsl:if test="not($context/@*[name() eq $attname])
            and not($context/@*[name() eq concat('css:border-', $direction, '-width')] eq '0pt')"> 
            <xsl:attribute name="{$attname}">
              <xsl:choose>
                <xsl:when test=". eq 'color'"><xsl:sequence select="'device-cmyk(0,0,0,1)'"/></xsl:when>
                <xsl:when test=". eq 'width'"><xsl:sequence select="'0.5pt'"/></xsl:when>
                <xsl:when test=". eq 'style'"><xsl:sequence select="'solid'"/></xsl:when>
              </xsl:choose>
            </xsl:attribute>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <!-- BEGIN: tables -->

  <xsl:template match="Column" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <colspec colname="c{position()}" colwidth="{idml2xml:pt-length(@SingleColumnWidth)}">
      <xsl:attribute name="colname" select="concat('c',position())"/>
    </colspec>
  </xsl:template>

  <xsl:variable name="idml2xml:epub-alternative-image-regex" as="xs:string" select="'^([_\-A-z0-9]+\.(jpe?g|tiff?|pdf|eps|ai|png)\p{Zs}*)([_\-A-z0-9]+\.(jpe?g|tiff?|pdf|eps|ai|png)\p{Zs}*)*$'"/>
  
  <xsl:template match="idml2xml:genTable" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="context-table" select="." as="element(idml2xml:genTable)"/>
    <xsl:variable name="table-style" select="//css:rule[@layout-type eq 'table'][@name = $context-table/@aid5:tablestyle]" as="element(css:rule)?"/>
    <xsl:variable name="head-count" select="number(@idml2xml:header-row-count)" as="xs:double"/>
    <xsl:variable name="body-count" select="number(@idml2xml:body-row-count)" as="xs:double"/>
    <xsl:variable name="foot-count" select="number(@idml2xml:footer-row-count)" as="xs:double"/>
    <xsl:variable name="alternative-image-name" select="string-join(descendant::*[self::idml2xml:genSpan[ancestor::*[self::idml2xml:genTable][1][. is current()]][@condition = 'EpubAlternative']], '')"
                  as="xs:string?"/>
    <informaltable>
      <xsl:attribute name="role" select="idml2xml:StyleName(@aid5:tablestyle)"/>
      <xsl:attribute name="idml2xml:layout-type" select="'table'"/>
      <xsl:apply-templates select="@css:* | @xml:* | @srcpath" mode="#current"/>
      <xsl:if test="$alternative-image-name[matches(., '\S')][matches(., $idml2xml:epub-alternative-image-regex, 'i')]">
        <xsl:variable name="alternative-image-name-parted" select="replace($alternative-image-name, '\.(jpe?g|tiff?|pdf|eps|ai|png)(\S)', '.$1 $2', 'i')" as="xs:string?"/>
         <alt>
          <xsl:analyze-string select="$alternative-image-name-parted" regex="{$idml2xml:epub-alternative-image-regex}" flags="i">
            <xsl:matching-substring>
              <xsl:for-each select="tokenize(normalize-space(.), ' ')">
                <inlinemediaobject><imageobject><imagedata fileref="{.}"></imagedata></imageobject></inlinemediaobject>
              </xsl:for-each>
            </xsl:matching-substring>
            <xsl:non-matching-substring/>
          </xsl:analyze-string>
        </alt>
      </xsl:if>
      <tgroup>
        <xsl:attribute name="cols" select="@aid:tcols"/>
        <xsl:apply-templates select="Column" mode="#current"/>
        <xsl:if test="$head-count gt 0">
          <thead>
            <xsl:for-each-group select="*[@aid:table = 'cell'][number(@aid:rowname) lt $head-count]" group-by="@aid:rowname">
              <xsl:call-template name="idml2xml:row">
                <xsl:with-param name="inherit-cellstyle" select="$table-style/@idml2xml:HeaderRegionCellStyle"/>
                <xsl:with-param name="table-style" select="$table-style"/>
              </xsl:call-template>
            </xsl:for-each-group>
          </thead>
        </xsl:if>
        <tbody>
          <xsl:for-each-group select="*[@aid:table = 'cell'][number(@aid:rowname) gt ($head-count - 1) and number(@aid:rowname) lt ($head-count + $body-count)]" group-by="@aid:rowname">
            <xsl:call-template name="idml2xml:row">
              <xsl:with-param name="inherit-cellstyle" select="$table-style/@idml2xml:BodyRegionCellStyle"/>
              <xsl:with-param name="table-style" select="$table-style"/>
            </xsl:call-template>
          </xsl:for-each-group>
        </tbody>
        <xsl:if test="$foot-count gt 0">
          <tfoot>
            <xsl:for-each-group select="*[@aid:table = 'cell'][number(@aid:rowname) ge ($head-count + $body-count)]" group-by="@aid:rowname">
              <xsl:call-template name="idml2xml:row">
                <xsl:with-param name="inherit-cellstyle" select="$table-style/@idml2xml:FooterRegionCellStyle"/>
                <xsl:with-param name="table-style" select="$table-style"/>
              </xsl:call-template>
            </xsl:for-each-group>
          </tfoot>
        </xsl:if>
      </tgroup>
    </informaltable>
  </xsl:template>

  <!-- sets alternative image name for table as alt in table and removes the conditional phrase then -->
  <!-- has to be improved -->
  <xsl:template match="idml2xml:genPara[matches(string-join(descendant::*[self::idml2xml:genSpan[@condition = 'EpubAlternative']], ''), 
    $idml2xml:epub-alternative-image-regex, 'i')]/idml2xml:genSpan[@condition = 'EpubAlternative']"
                mode="idml2xml:XML-Hubformat-remap-para-and-span" priority="3"/>
  
  <xsl:template name="idml2xml:row" as="element(dbk:row)*">
    <xsl:param name="inherit-cellstyle" select="''" as="xs:string?" tunnel="no"/>
    <xsl:param name="table-style" as="element(css:rule)?" tunnel="no"/>
    <row>
      <xsl:if test="$table-style/@idml2xml:StartRowFillCount + $table-style/@idml2xml:EndRowFillCount ne 0">
        <xsl:if test="position() &lt;= $table-style/@idml2xml:StartRowFillCount and
                      position() &gt; $table-style/@idml2xml:SkipFirstAlternatingFillRows and 
                      $table-style/@idml2xml:StartRowFillColor and
                      position() mod ($table-style/@idml2xml:StartRowFillCount + $table-style/@idml2xml:EndRowFillCount) ne 0">
          <xsl:attribute name="css:background-color" select="$table-style/@idml2xml:StartRowFillColor"/>
        </xsl:if>
        <xsl:if test="$table-style/@idml2xml:EndRowFillColor and
                      position() mod ($table-style/@idml2xml:StartRowFillCount + $table-style/@idml2xml:EndRowFillCount) eq 0">
          <xsl:attribute name="css:background-color" select="$table-style/@idml2xml:EndRowFillColor"/>
        </xsl:if>
      </xsl:if>
      <xsl:for-each select="current-group()">
        <entry>
          <xsl:apply-templates select="@xml:*, @css:*" mode="#current"/>
          <xsl:copy-of select="@*[ends-with(name(), 'Priority')]"/>
          <xsl:variable name="col" select="xs:integer(@aid:colname)+1" as="xs:integer"/>
          <xsl:variable name="colspan" select="xs:integer(@aid:ccols)" as="xs:integer"/>
          <xsl:choose>
            <xsl:when test="number(@aid:ccols) gt 1">
              <xsl:attribute name="namest" select="concat('c',$col)"/>
              <xsl:attribute name="nameend" select="concat('c',$col + $colspan - 1)"/>
              <xsl:attribute name="css:width" 
                select="idml2xml:pt-length(string(sum(../Column/@SingleColumnWidth[position() = ($col to $col + $colspan - 1)])))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="colname" select="concat('c',number(@aid:colname)+1)"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="number(@aid:crows) gt 1">
            <xsl:attribute name="morerows" select="number(@aid:crows)-1"/>
          </xsl:if>
          <xsl:attribute name="role" 
            select="idml2xml:StyleName(
                      if(@aid5:cellstyle eq 'None' and ($inherit-cellstyle ne '' and $inherit-cellstyle != 'n')) 
                      then $inherit-cellstyle 
                      else @aid5:cellstyle
                    )"/>
          <xsl:attribute name="idml2xml:layout-type" select="'cell'"/>
          <xsl:apply-templates mode="#current"/>
        </entry>
      </xsl:for-each>
    </row>
  </xsl:template>

  <!-- END: tables -->

  <xsl:template match="HyperlinkTextDestination |
                       HyperlinkTextSource"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- FIGURES, IMAGES -->
  
  <!--  * 
        * process shape-element-names, Rectangle, GraphicLine, Oval, Polygon, MultiStateObject
        * -->
  
  <xsl:function name="idml2xml:image-name" as="xs:string?">
    <xsl:param name="context" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$context/*[self::Image | self::*:EPS | self::*:WMF]/Link">
        <xsl:value-of select="concat($archive-dir-uri, 'images/', replace(replace($context/*[self::Image | self::*:EPS | self::*:WMF]/Link/@LinkResourceURI, '^(file:)?(.+)', '$2'), '^.+/(.+)$', '$1'))"/>
      </xsl:when>
      <!--<xsl:when test="$context/WMF[@ImageTypeName = '$ID/Windows Meta Files']">
        <xsl:value-of select="concat($archive-dir-uri, 'images/wmf-', $context/WMF/@Self, '.wmf')"/>
      </xsl:when>
      <xsl:when test="$context/WMF">
        <xsl:value-of select="concat($archive-dir-uri, 'images/wmf-', $context/WMF/@Self, '.tif')"/>
      </xsl:when>-->
      <xsl:otherwise>
        <xsl:value-of select="concat($archive-dir-uri, 'images/', $context/@Self, '-missing.tif')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="*[name() = $idml2xml:shape-element-names]" mode="idml2xml:XML-Hubformat-remap-para-and-span" priority="2">

    <xsl:variable name="suffix" as="xs:string"
      select="tr:identical-self-object-suffix(.)"/>
    <!--  *
          * process image properties in mode idml2xml:Images, see idml2xml/xsl/modes/Images.xsl  
          * -->
    <xsl:variable name="image-info" as="element(image)">
      <xsl:apply-templates select="." mode="idml2xml:Images"/>
    </xsl:variable>
    <xsl:variable name="id" select="concat('img_', $idml2xml:basename, '_', @Self, $suffix)" as="xs:string"/>
    <!--  *
          * construct file reference from LinkResourceURI (note that even embedded images have an URI)
          * -->
    <xsl:variable name="LinkResourceURI" 
                  select="if(@idml2xml:rectangle-embedded-source eq 'true') 
                          then idml2xml:image-name(.)
                          else replace(descendant::*[Link][1]/Link/@LinkResourceURI, '^(file:)?([a-zA-Z]:.+)$', '$1/$2')" as="xs:string"/>
    <xsl:variable name="fileref" as="xs:string?"
      select="(: check first for inserted filename labels from image export script, then use real link URI :)
              if (Properties/Label/KeyValuePair[@Key = ('letex:fileName', 'px:bildFileName')]) 
              (: correct the URI prefix of the base uri and replace the file name with letex:fileName :)
              then (
                     concat(
                       replace(
                         $LinkResourceURI, 
                         '^(.*/)?(.+)$', '$1'
                       ), 
                       (Properties/Label/KeyValuePair[@Key = 'letex:fileName'], Properties/Label/KeyValuePair[@Key = 'px:bildFileName'])[1]/@Value
                     )
                   ) 
              else $LinkResourceURI"/>
     <!-- *
          * mediaobject wrapper element
          * -->
    <mediaobject>
      <xsl:if test="exists($image-info/@shape-width)">
        <xsl:attribute name="css:width" select="$image-info/@shape-width"/>
      </xsl:if>
      <xsl:if test="exists($image-info/@shape-height)">
        <xsl:attribute name="css:height" select="$image-info/@shape-height"/>
      </xsl:if>
      <xsl:apply-templates select="@idml2xml:objectstyle | @idml2xml:layer" mode="#current"/>
      <xsl:apply-templates select="*[self::Image | self::EPS | self::PDF]/@srcpath" mode="idml2xml:XML-Hubformat-add-properties_tagged"/>
        <xsl:if test="$image-info/@alt">
          <alt><xsl:value-of select="replace($image-info/@alt, '&#xD;(&#xA;)?', ' ')"/></alt>
        </xsl:if>
      <imageobject>
        <xsl:if test="$preserve-original-image-refs eq 'yes' and Properties/Label/KeyValuePair[@Key = ('letex:fileName', 'px:bildFileName')]">
          <xsl:attribute name="condition" select="'web'"/>
        </xsl:if>
        <xsl:if test="@idml2xml:rectangle-embedded-source eq 'true'">
          <xsl:attribute name="role" select="'hub:embedded'"/>
        </xsl:if>
        <imagedata fileref="{$fileref}">
          <xsl:if test="$image-info/@width">
            <xsl:attribute name="css:width" select="concat($image-info/@width, 'px')"/>
          </xsl:if>
          <xsl:if test="$image-info/@height">
            <xsl:attribute name="css:height" select="concat($image-info/@height, 'px')"/>
          </xsl:if>
          <xsl:attribute name="xml:id" select="$id"/>
        </imagedata>
      </imageobject>
      <!-- generate a 2nd image object to preserve the original file 
           reference if the export script had generated a filename label. -->
      <xsl:if test="$preserve-original-image-refs eq 'yes' 
                    and Properties/Label/KeyValuePair[@Key = ('letex:fileName', 'px:bildFileName')]
                    and @idml2xml:rectangle-embedded-source eq 'false'">
        <imageobject condition="print" css:width="{$image-info/@width}px" css:height="{$image-info/@height}px">
          <imagedata fileref="{$LinkResourceURI}"/>
        </imageobject>
      </xsl:if>
    </mediaobject>

    <!--  * 
          * generate virtual result documents, which will be decoded by idml_tagged2hub.xpl,
          * otherwise the resulting document stays base64 encoded. Avoid writing duplicate images
          * -->
    <xsl:if test="@idml2xml:rectangle-embedded-source eq 'true' 
                  and 
                 (key('idml2xml:filerefs-for-embedded-images', *[self::*:EPS | self::*:Image]/*:Link/@LinkResourceURI)[1] is . or *:WMF)">
      <xsl:result-document href="{$fileref}">
        <data xmlns="http://transpect.io/idml2xml" 
          content-type="{(EPS, PDF, WMF, Image)[1]/local-name()}"
          encoding="base64"
          embedded-in-idml="true">
          <!-- "it's inadvisable to write @xml:* attributes as attribute value templates, 
            see https://saxonica.plan.io/issues/2362 for more details -->
          <xsl:attribute name="xml:base" select="$fileref"/>
          <xsl:attribute name="xml:id" select="$id"/>
          <!--  *
                * if you get 0KB sized images, probably no Contents element exists
                * -->
          <xsl:sequence select="(Contents/text(), WMF/Properties/Contents/text())[1]"/>
        </data>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>
  

  <xsl:key name="idml2xml:filerefs-for-embedded-images" 
          match="*[name() = $idml2xml:shape-element-names]" 
            use="*[self::*:EPS | self::*:Image]/*:Link[@StoredState = 'Embedded']/@LinkResourceURI"/>

  <!-- footnotes -->
  <xsl:template match="Footnote" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <footnote>
      <xsl:apply-templates mode="#current"/>
    </footnote>
  </xsl:template>


  <!-- notes -->
  <xsl:template match="Note" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <note>
      <info>
        <author>
          <personname>
            <xsl:value-of select="@idml2xml:UserName"/>
          </personname>
        </author>
        <date role="created">
          <xsl:value-of select="@idml2xml:CreationDate"/>
        </date>
        <date role="modified">
          <xsl:value-of select="@idml2xml:ModificationDate"/>
        </date>
      </info>
      <xsl:apply-templates mode="#current"/>
    </note>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[*[name() = $idml2xml:shape-element-names]]
                                       [not(@condition)]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="idml2xml:XmlStory" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"/>
  
  <xsl:template match="text()" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:analyze-string select="." regex="&#x2028;">
      <xsl:matching-substring>
        <br/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <!-- remove other namespaces -->
  <xsl:template match="node()[ namespace-uri() eq '' and self::* ]" 
    mode="idml2xml:XML-Hubformat-remap-para-and-span"
    priority="-0.7">
    <xsl:element name="{local-name()}" namespace="http://docbook.org/ns/docbook">
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:element>
  </xsl:template>


  <!-- handle imported/tagged elements -->
  <xsl:template match="*[name() = tokenize($hub-other-elementnames-whitelist,',') and not(.//idml2xml:genFrame[idml2xml:same-scope(., current())])]" 
    mode="idml2xml:XML-Hubformat-remap-para-and-span"
    priority="-0.5">
    <xsl:copy>
      <xsl:if test="@aid:pstyle">
        <xsl:attribute name="role" select="@aid:pstyle"/>
        <xsl:attribute name="idml2xml:layout-type" select="'para'"/>
      </xsl:if>
      <xsl:apply-templates select="@* except @aid:pstyle, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-cleanup-paras-and-br -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  <xsl:template match="css:rule[@layout-type eq 'cell'][not(@name = distinct-values(//dbk:entry/@role))]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <!-- delete special unused cell styles: HeaderRegionCellStyle, BodyRegionCellStyle, FooterRegionCellStyle-->
    <xsl:if test="$all-styles = 'yes'">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="css:rule[@layout-type eq 'table']/@layout-type" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:next-match/>
    <xsl:attribute name="css:border-collapse" select="'collapse'"/>
  </xsl:template>
  
  <xsl:template match="dbk:entry/@idml2xml:*" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
	
	<xsl:template match="css:rule[@layout-type eq 'para']/@css:display[. eq 'block']" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <!-- was only a temporary means in order to mark inactive lists -->
  </xsl:template>
  
  <xsl:template match="dbk:link[not(node())]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <!-- Can appear if HyperlinkTextSources are wrapped only around a Br. -->
  </xsl:template>
  
  <!-- set or overwrite border-*-width attributes, when opposite cell is set to '0pt' and has more priority -->
  <xsl:template match="dbk:entry[@idml2xml:*[ends-with(name(), 'Priority')]]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:variable name="context" select="." as="element(dbk:entry)"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each select="('Top', 'Right', 'Bottom', 'Left')[
                              $context/@*/local-name() = concat(., 'EdgeStrokePriority')
                            ]">
        <xsl:call-template name="idml2xml:set-zero-border-width-for-opposite-entry">
          <xsl:with-param name="entry" select="$context"/>
          <xsl:with-param name="direction" select="current()"/>
        </xsl:call-template>
<!--        <xsl:sequence select="idml2xml:set-zero-border-width-for-opposite-entry($context, current())"/>-->
      </xsl:for-each>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
<!--  as="attribute()?"-->
  <xsl:template name="idml2xml:set-zero-border-width-for-opposite-entry">
    <xsl:param name="entry" as="element(dbk:entry)" />
    <xsl:param name="direction" as="xs:string" />
    <xsl:variable name="opposite-entry-element" as="element(dbk:entry)*">
      <xsl:choose>
        <xsl:when test="$direction eq 'Top'">
          <xsl:sequence select="$entry/ancestor::dbk:row[1]/preceding-sibling::dbk:row[1]/dbk:entry[
                                  idml2xml:get-colnums(.) = idml2xml:get-colnums($entry)
                                ]"/>
        </xsl:when>
        <xsl:when test="$direction eq 'Bottom'">
          <xsl:sequence select="$entry/ancestor::dbk:row[1]/following-sibling::dbk:row[1]/dbk:entry[
                                  idml2xml:get-colnums(.) = idml2xml:get-colnums($entry)
                                ]"/>
        </xsl:when>
        <xsl:when test="$direction eq 'Left'">
          <xsl:sequence select="$entry/preceding-sibling::dbk:entry[1]"/>
        </xsl:when>
        <xsl:when test="$direction eq 'Right'">
          <xsl:sequence select="$entry/following-sibling::dbk:entry[1]"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
<!--    <xsl:message select="'OPP-ELT: ', $opposite-entry-element"/>-->
    <xsl:variable name="opposite-border-name" as="xs:string"
      select="if($direction eq 'Top') then 'Bottom' 
              else if($direction eq 'Right') then 'Left'
              else if($direction eq 'Left') then 'Right'
              else 'Top'"/>
    
    <xsl:variable name="opposite-border-has-higher-importance-and-zero-width" as="xs:boolean">
      <xsl:sequence select="exists($opposite-entry-element[
                              (
                                number($entry/@idml2xml:*[local-name() eq concat($direction, 'EdgeStrokePriority')]) 
                                  ge number(@idml2xml:*[local-name() eq concat($opposite-border-name, 'EdgeStrokePriority')]) 
                                and
                                number($entry/@idml2xml:AppliedCellStylePriority) ge number(@idml2xml:AppliedCellStylePriority) 
                                and
                                $entry/@css:*[local-name() eq concat('border-', lower-case($direction), '-width')] = '0pt'
                              )
                              or
                              (
                                number($entry/@idml2xml:*[local-name() eq concat($direction, 'EdgeStrokePriority')]) 
                                  le number(@idml2xml:*[local-name() eq concat($opposite-border-name, 'EdgeStrokePriority')]) 
                                and
                                number(@idml2xml:*[local-name() eq concat($opposite-border-name, 'EdgeStrokePriority')]) 
                                  ge number(@idml2xml:AppliedCellStylePriority) 
                                and
                                @css:*[local-name() eq concat('border-', lower-case($opposite-border-name), '-width')] = '0pt'
                              )
                              or
                              (
                                number(@idml2xml:*[local-name() eq concat($opposite-border-name, 'EdgeStrokePriority')]) 
                                  eq number($entry/@idml2xml:*[local-name() eq concat($direction, 'EdgeStrokePriority')])
                                and
                                number(@idml2xml:AppliedCellStylePriority) gt number($entry/@idml2xml:AppliedCellStylePriority) 
                                and
                                key('idml2xml:css-rule-by-name', @role, root($entry))/@css:*[local-name() eq concat('border-', lower-case($opposite-border-name), '-width')][. eq '0pt']
                              )
                            ])"/>
    </xsl:variable>
    <xsl:if test="$opposite-border-has-higher-importance-and-zero-width">
      <xsl:attribute name="{concat('css:border-', lower-case($direction), '-width')}" select="'0pt'"/>
    </xsl:if>
  </xsl:template>

  <xsl:function name="idml2xml:get-colnums" as="xs:integer+">
    <xsl:param name="entry" as="element(dbk:entry)" />
    <xsl:sequence select="if($entry/@namest and $entry/@nameend) 
                          then for $i in (xs:integer(substring-after($entry/@namest, 'c')) to xs:integer(substring-after($entry/@nameend, 'c'))) return $i
                          else xs:integer(substring-after($entry/@colname, 'c'))"/>
  </xsl:function>
  
  <xsl:template match="text()" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:value-of select="replace(., '&#xfeff;', '')"/>
  </xsl:template>


  <xsl:template match="@*[name() = ('css:text-decoration-width', 'css:text-decoration-offset', 'css:text-decoration-color', 'css:text-decoration-style')][../@css:text-decoration-line = 'none']"
                mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="2"/>
  <xsl:template match="  @css:border-top-width[. != '0pt'][../@css:border-top = 'none'] 
                       | @css:padding-top[../@css:border-top = 'none' or matches(., '^-')]
                       | @css:border-top-style[../@css:border-top = 'none'] 
                       | @css:border-top-color[../@css:border-top = 'none']"
                mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="2"/>
  <xsl:template match="@css:border-bottom-width[../@css:border-bottom = 'none'] | @css:padding-bottom[../@css:border-bottom = 'none' or matches(., '^-')] | @css:border-bottom-color[../@css:border-bottom = 'none'] | @css:border-bottom-style[../@css:border-bottom = 'none']"
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  
  <xsl:template match="@css:border-bottom | @css:border-top| @hub:restart-at-higher-level 
    | @idml2xml:aux-list-level | @idml2xml:layout-type | @idml2xml:aux-list-restart | @hub:numbering-family
    | @hub:numbering-continue | @idml2xml:aux-list-famlvl | @idml2xml:aux-list-fam | @idml2xml:aux-list-picture-string
    | @hub:numbering-picture-string | @*:numbering-starts-at | @*:numbering-level | @numbering-format
    | @*:numbering-expression | @*:numbering-inline-stylename" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  
    <xsl:template match="dbk:entry[key('idml2xml:style-by-role', @role)[@css:vertical-align = 'top' or not(@css:vertical-align)]]/@css:vertical-align[. = 'top']" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  
  <xsl:template match="  @css:border-top-color[. = 'transparent'][../@css:border-top-width[. = '0pt']] 
                       | @css:border-bottom-color[. = 'transparent'][../@css:border-bottom-width[. = '0pt']] 
                       | @css:border-top-style[../@css:border-top-width[. = '0pt']][../@css:border-top-color[. = 'transparent']] 
                       | @css:border-bottom-style[../@css:border-bottom-width[. = '0pt']][../@css:border-bottom-color[. = 'transparent']]" 
                mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  <xsl:template match="@css:border-width[../@layout-type = 'para'][../@css:border-top = 'none'][../@css:border-bottom = 'none']" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  <xsl:template match="*[@condition = ('FigureRef', 'StoryID')]/@css:display[. = 'none'] | @condition[. = '']" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  <xsl:template match="@css:font-style[matches(., '(normal .+|.+ normal)')]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
      <!-- can happen that several contrary font-style attributes are created. normal won't win then. and to avoid invalid CSS, we discard it -->
    <xsl:attribute name="{name()}" select="replace(., '(normal | normal)', '')"/>
  </xsl:template>
	<xsl:template match="css:rule[@layout-type = 'para']/@css:font-variant[. = 'normal']" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  <xsl:template match="dbk:phrase[@srcpath][count(@*) = 1]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
  	<xsl:apply-templates mode="#current"/>
  </xsl:template>
	
  <xsl:template match="@css:text-decoration-width[. = '-9999pt']" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <!-- the negative value seems to be a default. it results in invalid css though-->
    <xsl:attribute name="{name()}" select="'1pt'"/>
  </xsl:template>
  
  <xsl:template match="@css:text-decoration-offset[. = '-9999pt']" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  

	<xsl:template match="@*[matches(name(), 'color')][matches(., '^[\S]+\s[\S]+\s[\S]+$')]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
		<!-- LAB colours can be reported by schematron on idml. But as css:color attribute it is not valid and will be replace by black-->
		<xsl:attribute name="{name()}" select="'device-cmyk(0,0,0,1)'"/>
	</xsl:template>
	
  <xsl:template match="dbk:superscript
                         [dbk:footnote]
                         [every $c in (text()[normalize-space()], *) 
                          satisfies ($c/self::dbk:footnote)]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <phrase>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </phrase>
  </xsl:template>

  <!-- Problem: some properties that are generated from the proplist can double with the css:rule 
       declarations, because the proplist is not very detailed. 
       Example: css:font-style="italic" is given in css:rule + local override is 
       FontStyle="LF4 SemiLight Italic". This is mapped to css:font-style="italic" as well. 
       Later two <italic>-tags would be created.-->
  
  <xsl:template match="@*[matches(name(), '^(css:|xml:lang)')]
                         [key('idml2xml:css-rule-by-name', ../@role)/@*[name() = name(current())]
                                                                       [. = current()]]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
     
   <!-- Make css:rule/@name and @role unique in case that there are rules with the same name, but different
   layout types: -->
   
   <xsl:template match="css:rule/@name[count(key('idml2xml:css-rule-by-name', .)) gt 1] 
                        | @role[not(parent::dbk:keyword)][count(key('idml2xml:css-rule-by-name', .)) gt 1]" 
                        mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="2">
     <xsl:variable name="string-replacements-applied" as="attribute()"><!-- see approx. 70 lines below -->
       <xsl:next-match/>
     </xsl:variable>
     <xsl:attribute name="{name()}" select="string-join((../@*:layout-type, $string-replacements-applied), '__')"/>
   </xsl:template>
   
 
  <!-- delete idml2xml:layer attribute if only one layer is used -->
   <xsl:template match="@idml2xml:layer" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
     <xsl:param name="multiple-layers" as="xs:boolean" tunnel="yes"/>
     <xsl:if test="$multiple-layers">
       <xsl:copy/>
     </xsl:if>
   </xsl:template>
   
  <!-- §§§ GI 2012-09-30 Needs review.
       Are there any dbk:phrase[@role='br'], or is it dbk:br now?
       Should it apply to dbk:br?
       -->
  <xsl:template match="dbk:phrase[@role='br'][ following-sibling::*[ self::dbk:para ] ] |
		       dbk:phrase[@role='br'][ not(following-sibling::*) and parent::dbk:para ]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  
  <!-- Unwrap tables in a character style region if there's no other content in that region than the tables.
       Reason: tables in phrases are not permitted by the document model.
       If there are documents with tables *and* other text in phrases, we need to implement an anchoring
       mechanism such as the one for text frames. -->
  <xsl:template match="*[self::dbk:phrase or self::dbk:subscript or self::dbk:superscript]
                        [not(@remap)][count(node()) eq count(dbk:informaltable)]" 		
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="2">
    <xsl:apply-templates mode="#current" />
  </xsl:template>
  
  <xsl:template match="@*" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:copy/>
  </xsl:template>

  <!-- Links around unanchored mediaobjects may occur on the top level --> 
  <xsl:template match="*[self::dbk:mediaobject or self::dbk:link][not(parent::dbk:para or parent::dbk:phrase or parent::dbk:link or parent::dbk:superscript or parent::dbk:subscript)]" 		
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="2">
    <xsl:element name="para">
      <xsl:next-match/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="dbk:mediaobject[(some $n in ancestor::dbk:para[not(dbk:informaltable or dbk:phrase/dbk:informaltable or dbk:sidebar[@remap eq 'HiddenText'])][1]//text()[not(parent::dbk:alt)] satisfies (matches($n, '\S')))
                                       or
                                       (exists(parent::dbk:link))]" 		
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <inlinemediaobject>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </inlinemediaobject> 
  </xsl:template>
  
  <xsl:template match="dbk:para[parent::dbk:para]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <phrase role="idml2xml-para {@role}">
      <xsl:apply-templates select="@* except @role | node()" mode="#current"/>
    </phrase>
  </xsl:template>

  <xsl:template match="@parastyle" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" />

  <xsl:template 
      match="@*:AppliedParagraphStyle | @*:AppliedCharacterStyle" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" />

  <xsl:template 
      match="*[not( name() = ($hubformat-elementnames-whitelist, tokenize($hub-other-elementnames-whitelist,',')) )]" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:variable name="content" select="string-join(.,'')"/>
    <xsl:message>
      INFO: Removed non-hub element '<xsl:value-of select="name()"/>'<xsl:value-of select="if($content eq '') then ' (without content)' else ''"/>
      <xsl:if test="$content ne ''">
        ===
        Text content: <xsl:value-of select="$content"/>
        ===</xsl:if>
    </xsl:message>
  </xsl:template>


  <xsl:template match="mml:*" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="3">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:imageobject[*:imagedata[mml:*]]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="3">
    <alt><xsl:value-of select="*:imagedata/@fileref"/></alt>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="*:imagedata[mml:*]/@fileref" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="3"/>
  
  <!-- Make @role and css:rule/@name compliant with the rules for CSS identifiers
       http://www.w3.org/TR/CSS21/syndata.html#characters --> 

  <xsl:template match="  @role[not($hub-version eq '1.0')][not(starts-with(., 'hub:'))] 
                       | css:rule/@name 
                       | dbk:linked-style/@name
                       | @hub:numbering-inline-stylename" 
                mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:attribute name="{name()}" select="replace(replace(replace(., '[^_~&#x2dc;a-zA-Z0-9-]', '_'), '[~&#x2dc;]', '_-_'), '^(\I)', '_$1')"/>
    <!-- [~˜] is treated as a special character: by convention, typesetters may add style variants
        that should be treated equivalently by adding a tilde, followed by arbitrary name components -->
  </xsl:template>

  <!-- for finding sidebar[@linkend] to a given anchor[@xml:id]: -->
  <xsl:key name="idml2xml:linking-item-by-id" match="*[@linkend]" use="@linkend" />
  <!-- for finding anchor[@xml:id] to a given sidebar[@linkend]: -->
  <xsl:key name="idml2xml:linking-item-by-linkend" match="*[@*:id]" use="@*:id" />
  
  <!-- Replace anchors in groups with the items that they point to (typically, sidebar of the TextFrame type,
       or Rectangles) --> 
  <!-- GI 2015-11-19: But then we’ll get nested sidebars which violates the DocBook schema -->
  <xsl:template 
    match="dbk:sidebar[@remap = ('TextFrame','Group')]/dbk:anchor[exists(key('idml2xml:linking-item-by-id', @xml:id))]" 
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:for-each select="key('idml2xml:linking-item-by-id', @xml:id)">
      <xsl:copy copy-namespaces="no">
        <xsl:apply-templates select="@* except @linkend, node()" mode="#current"/>
      </xsl:copy>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template 
    match="*[@linkend][key('idml2xml:linking-item-by-linkend', @linkend)
                        /self::dbk:anchor/parent::dbk:sidebar[@remap eq 'Group']
                      ]" 
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>

  <!-- remove @linked on Groups when they’re not anchored (there ARE anchored Groups) -->
  <xsl:template match="dbk:sidebar[@remap = ('TextFrame', 'Group')]/@linkend[not(key('idml2xml:linking-item-by-linkend', .))]"
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>  
  
  <xsl:template match="/*" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="0.75">
    <xsl:variable name="orphaned-indexterm-para-candidates" as="element(dbk:para)*"
      select="dbk:para[normalize-space()]
                      [not(every $n in node() 
                           satisfies ($n/self::dbk:mediaobject | $n/self::dbk:informaltable | $n/self::dbk:anchor))]
                      [not(matches(@role, '(imprint|index|toc|title|note)'))]
                      [not(.//@condition)]"/>
    <xsl:variable name="orphaned-indexterm-para" as="element(dbk:para)?">
      <xsl:choose>
        <xsl:when test="count($orphaned-indexterm-para-candidates) = 0">
          <xsl:sequence select="dbk:para[1]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$orphaned-indexterm-para-candidates[count($orphaned-indexterm-para-candidates) idiv 2 + 1]"/>
          <!-- not the last as previously because the last para might get discarded (unanchored table caption 
            continuations, etc., see https://redmine.le-tex.de/issues/5782). 
            The first paras are also likely to be discarded (imprint, ToC, etc.). -->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="all-list-paras" as="element(dbk:para)*"
                 select="/dbk:hub//dbk:para[
                                    (
                                      @*[matches(name(), 'hub:numbering-(continue|starts-at|level)|css:list-style-type')] 
                                      or 
                                      @css:display = ('list-item') 
                                      or 
                                      key('idml2xml:style-by-role', @role)[@css:display = 'list-item']
                                    )
                                    and
                                    (key('idml2xml:style-by-role', @role)/@css:list-style-type, @css:list-style-type)[last()] = $numbered-list-styles]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="orphaned-indexterm-para" as="element(dbk:para)?" tunnel="yes" select="$orphaned-indexterm-para"/>
      	<xsl:with-param name="all-list-paras" as="element(dbk:para)*" tunnel="yes" select="$all-list-paras"/>
        <xsl:with-param name="multiple-layers" as="xs:boolean" tunnel="yes" select="count(distinct-values(//@*[local-name()='layer'])) &gt; 1"/>
      </xsl:apply-templates>
      <xsl:if test="not($orphaned-indexterm-para)">
        <para>
          <xsl:call-template name="orphaned-indexterms"/>
        </para>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="orphaned-indexterms">
    <xsl:for-each select="//idml2xml:indexterms/dbk:indexterm[not(@page-reference)]">
      <xsl:copy copy-namespaces="no">
        <xsl:apply-templates select="@* except @see-crossref-topics, node()" mode="#current"/>
        <xsl:if test="@see-crossref-topics and not(dbk:primary/dbk:see)">
          <see>
            <xsl:value-of select="substring-after(@see-crossref-topics, 'Topicn')"/>
          </see>
        </xsl:if>
      </xsl:copy>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="dbk:para" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:param name="orphaned-indexterm-para" as="element(dbk:para)?" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test=". is $orphaned-indexterm-para">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
          <xsl:call-template name="orphaned-indexterms"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:variable name="numbered-list-styles" select="('decimal', 'lower-roman', 'upper-roman', 'lower-alpha', 'upper-alpha')" as="xs:string+"/>
	
	<xsl:key name="idml2xml:list-para-by-fam" match="dbk:para[@idml2xml:aux-list-fam]"
	  use="@idml2xml:aux-list-fam"/>
	
  <xsl:template match="dbk:para[exists(node())
                                or
                                (
                                  exists(@idml2xml:aux-list-fam) 
                                  and 
                                  ('', (key('idml2xml:style-by-role', @role)[@layout-type = 'para'], .)//@css:list-style-type)[last()] = $numbered-list-styles 
                                  and 
                                  @idml2xml:aux-list-picture-string ne ''
                                )]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="3">
    <xsl:param name="orphaned-indexterm-para" as="element(dbk:para)?" tunnel="yes"/>
    <xsl:param name="all-list-paras" as="element(dbk:para)*" tunnel="yes"/>
    <xsl:variable name="context" select="." as="element(dbk:para)"/>
    <xsl:variable name="rule" select="key('idml2xml:style-by-role', @role)[@layout-type = 'para']" as="element(css:rule)?"/>
    <xsl:variable name="list-style-type" as="xs:string" select="('', ($rule, $context)//@css:list-style-type)[last()]"/>
    <xsl:choose>
      <xsl:when test="exists(@idml2xml:aux-list-fam) 
                      and 
                      $list-style-type = $numbered-list-styles 
                      and 
                      @idml2xml:aux-list-picture-string ne ''
                      and 
                      (
                        exists(node()) 
                        or
                        exists(following-sibling::*)
                      ) (: http://svn.le-tex.de/svn/ltxbase/Difftestdata/Hogrefe/hogrefe.de/ADHOC_MO/02641/idml/101026_02641_ADHOC_MO.idml
                                        after 'Das Basisverhalten des Therapeuten sollte' :)
                      ">
        <!-- Apparently it is not necessary that there are nodes. Counterexample: 
          http://svn.le-tex.de/svn/ltxbase/Difftestdata/evolve-hub-lists/idml/M_1_001.idml
          second para with role="Proof_Line-Numbers".
          The criterion seems to be: Either there be nodes or a following-sibling para
        -->
        <xsl:variable name="same-list-family" as="element(dbk:para)*" 
          select="key('idml2xml:list-para-by-fam', @idml2xml:aux-list-fam)[. &lt;&lt; current()][not(ancestor::dbk:sidebar[@remap = 'HiddenText'])] union current()"/>
        <xsl:variable name="is-list-item" as="xs:boolean"
          select="(($rule, $context)//@css:display[not(ancestor::dbk:sidebar[@remap = 'HiddenText'])])[last()] = 'list-item'"/>
        <xsl:variable name="all-list-styles" as="xs:string*"
          select="key('idml2xml:list-styles', $numbered-list-styles)[@*:numbering-level = $rule/@*:numbering-level]/@name"/>
        <xsl:variable name="same-list-famlvl" as="element(dbk:para)*"
          select="$same-list-family[@idml2xml:aux-list-level = current()/@idml2xml:aux-list-level]"/>
        <xsl:variable name="start" as="element(dbk:para)?" 
          select="(($same-list-famlvl)[@idml2xml:aux-list-restart = 'true'])[last()]"/>
        <xsl:variable name="in-between" as="element(dbk:para)*"
          select="$same-list-famlvl[not(@css:display = 'block')]
                                   [(@role = $all-list-styles 
                                     or (
                                      @css:list-style-type
                                      and
                                      @css:list-style-type = $numbered-list-styles
                                      and
                                      @css:display = 'list-item'
                                     )
                                  )
                                  and
                                  (key('idml2xml:style-by-role', @role)[@css:display = 'list-item']/@css:list-style-type, @css:list-style-type)[last()] 
                                   = $numbered-list-styles
                                 ]
                                 [. &gt;&gt; $start]"/>
        <xsl:variable name="list-start" as="xs:string"
          select="(($start/@hub:numbering-starts-at, key('idml2xml:style-by-role', $start/@role)/@hub:numbering-starts-at)[1], '1')[1]"/>
        <xsl:variable name="override" as="xs:integer?" 
          select="if (
                       $list-start castable as xs:integer
                     ) 
                  then xs:integer($list-start) + count($in-between) 
                  else ()"/>
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:if test="$is-list-item">
            <xsl:variable name="list-item-position" as="xs:integer?"
              select="if (exists($override)) then () else
                      count(
                        $context/preceding-sibling::*[
                          (@css:list-style-type, key('idml2xml:style-by-role', @role)/@css:list-style-type)[1] = $numbered-list-styles
                        ]
                      ) + 1"/>
<!--            <xsl:if test="@srcpath='Stories/Story_u105.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[47]'">
              <xsl:message>
                <xsl:element name="phrase">
              <xsl:attribute name="role" select="'hub:identifier'"/>
              <!-\- The picture strings are not reproduced 1:1 according to their levels -\->
              <xsl:variable name="picture-string"
                select="(@hub:numbering-picture-string, $rule/@hub:numbering-picture-string)[1]" as="xs:string?"/>
              <xsl:variable name="picture-result"
                select="(
                          replace(
                            replace(
                              $picture-string, 
                              '\^#', 
                              idml2xml:numbering-format($list-style-type)
                            ), 
                            '(\^[tm&gt;&lt;=pJBeH\|/\.]|\^\d\.?)',
                            ''
                          ), 
                          $list-style-type
                        )[1]"
                as="xs:string"/>
              <xsl:number format="{idml2xml:numbering-format($picture-result)}" value="($override, $list-item-position)[1]"/>
              <!-\-    							<xsl:if test="$context[@srcpath = 'Stories/Story_u2cc.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[12]/CharacterStyleRange[2]/Table[1]/Cell[3]/ParagraphStyleRange[5]']">
    								<xsl:message select="'###########',$override, '|||', $list-item-position, ' ❧❧❧ ', idml2xml:numbering-format($list-style-type), '  |||| ', $picture-string, '  |||| ', $picture-result"/>
    							</xsl:if>-\->
            </xsl:element>
              </xsl:message>
            </xsl:if>-->
            <xsl:element name="phrase">
              <xsl:attribute name="role" select="'hub:identifier'"/>
              <!-- The picture strings are not reproduced 1:1 according to their levels -->
              <xsl:variable name="picture-string"
                select="(@hub:numbering-picture-string, $rule/@hub:numbering-picture-string)[1]" as="xs:string?"/>
              <xsl:variable name="picture-result"
                select="(
                          replace(
                            replace(
                              $picture-string, 
                              '\^#', 
                              idml2xml:numbering-format($list-style-type)
                            ), 
                            '(\^[tm&gt;&lt;=pJBeH\|/\.]|\^\d\.?)',
                            ''
                          ), 
                          $list-style-type
                        )[1]"
                as="xs:string"/>
              <xsl:number format="{idml2xml:numbering-format($picture-result)}" value="($override, $list-item-position)[1]"/>
              <!--    							<xsl:if test="$context[@srcpath = 'Stories/Story_u2cc.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[12]/CharacterStyleRange[2]/Table[1]/Cell[3]/ParagraphStyleRange[5]']">
    								<xsl:message select="'###########',$override, '|||', $list-item-position, ' ❧❧❧ ', idml2xml:numbering-format($list-style-type), '  |||| ', $picture-string, '  |||| ', $picture-result"/>
    							</xsl:if>-->
            </xsl:element>
          </xsl:if>
          <xsl:apply-templates select="node()" mode="#current"/>
          <xsl:if test=". is $orphaned-indexterm-para">
            <xsl:call-template name="orphaned-indexterms"/>
          </xsl:if>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- the problem still exists that lists may not be recognized after style name mapping because of the indentation.-->
  </xsl:template>
	
  <xsl:function name="idml2xml:numbering-format" as="xs:string">
    <xsl:param name="list-style-type" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$list-style-type = 'decimal'"><xsl:sequence select="'1'"/></xsl:when>
      <xsl:when test="$list-style-type = 'lower-roman'"><xsl:sequence select="'i'"/></xsl:when>
      <xsl:when test="$list-style-type = 'upper-roman'"><xsl:sequence select="'I'"/></xsl:when>
      <xsl:when test="$list-style-type = 'lower-alpha'"><xsl:sequence select="'a'"/></xsl:when>
      <xsl:when test="$list-style-type = 'upper-alpha'"><xsl:sequence select="'A'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="$list-style-type"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
	
  <xsl:template match="idml2xml:indexterms//dbk:primary[dbk:see]" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <primary>
      <xsl:apply-templates select="node()[not(self::dbk:see)]" mode="#current"/>
    </primary>
    <xsl:apply-templates select="dbk:see" mode="#current"/>
  </xsl:template>

  <xsl:template match="idml2xml:indexterms" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="3"/>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-without-srcpath -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-without-srcpath" />

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: idml2xml:Hubformat-extract-text -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="dbk:info" mode="idml2xml:XML-Hubformat-extract-text" />
  <xsl:template match="dbk:indexterm" mode="idml2xml:XML-Hubformat-extract-text" />

  <xsl:template 
    match="dbk:para[
             node() and
             not(count(node()) eq 1 and *[local-name() = ('mediaobject','anchor')])
           ]" 
    mode="idml2xml:XML-Hubformat-extract-text">
    <xsl:apply-templates mode="#current"/>
    <xsl:value-of select="'&#xa;'"/>
  </xsl:template>

  <!-- remove SOFT HYPHEN (U+00AD) -->
  <xsl:template match="text()" mode="idml2xml:XML-Hubformat-extract-text">
    <xsl:value-of select="replace(., '&#xad;', '')"/>
  </xsl:template>

</xsl:stylesheet>
