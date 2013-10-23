<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
    version="2.0"
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs = "http://www.w3.org/2001/XMLSchema"
    xmlns:css="http://www.w3.org/1996/css"
    xmlns:aid = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5 = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml = "http://www.le-tex.de/namespace/idml2xml"
    xmlns:letex = "http://www.le-tex.de/namespace"
    xmlns:xlink = "http://www.w3.org/1999/xlink"
    xmlns:dbk = "http://docbook.org/ns/docbook"
    xmlns:hub = "http://www.le-tex.de/namespace/hub"
    xmlns="http://docbook.org/ns/docbook"
    exclude-result-prefixes="idPkg aid5 aid xs idml2xml xlink dbk letex css hub"
    >

  <xsl:import href="../propmap.xsl"/>

  <xsl:variable 
      name="hubformat-elementnames-whitelist"
      select="('anchor', 'book', 'hub', 'Body', 'para', 'info', 'informaltable', 'table', 'tgroup', 
               'colspec', 'tbody', 'row', 'entry', 'mediaobject', 'inlinemediaobject', 'tab', 'tabs', 'br',
               'imageobject', 'imagedata', 'phrase', 'emphasis', 'sidebar',
               'superscript', 'subscript', 'link', 'xref', 'footnote',
               'keywordset', 'keyword', 'indexterm', 'primary', 'secondary', 'tertiary',
               'see', 'seealso',
               'css:rules', 'css:rule', 'linked-style',
               'styles', 'parastyles', 'inlinestyles', 'objectstyles', 'cellstyles', 'tablestyles', 'style', 'thead' 
              )" as="xs:string+"/>

  <xsl:key name="idml2xml:by-Self" match="*[@Self]" use="@Self" />

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
          select="key('idml2xml:style', for $s in distinct-values(//*/@aid5:cellstyle) return idml2xml:generate-style-name-variants('CellStyle', $s) )"
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
                else key('idml2xml:style', for $s in distinct-values(//*/@aid:cstyle) return idml2xml:generate-style-name-variants('CharacterStyle', $s) )"
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
                else key('idml2xml:style', for $s in distinct-values(//*/@aid5:cellstyle) return idml2xml:generate-style-name-variants('CellStyle', $s) )"
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
      <xsl:apply-templates select="if (Properties/BasedOn/@type = 'object') 
                                   then key('idml2xml:style', idml2xml:StyleNameEscape(Properties/BasedOn))
                                   else 
                                     if (Properties/BasedOn/@type = 'string')
                                     then key('idml2xml:style-by-Name', Properties/BasedOn)
                                     else ()" mode="#current">
        <xsl:with-param name="wrap-in-style-element" select="false()"/>
      </xsl:apply-templates>
      <xsl:variable name="mergeable-atts" as="element(*)*">
        <xsl:apply-templates select="@*, Properties/*[not(self::BasedOn)]" mode="#current" />
      </xsl:variable>
      <xsl:for-each-group select="$mergeable-atts[self::idml2xml:attribute]" group-by="@name">
        <xsl:variable name="att" as="element(idml2xml:attribute)">
          <idml2xml:attribute name="{current-grouping-key()}"><xsl:value-of select="current-group()" /></idml2xml:attribute>  
        </xsl:variable>
        <xsl:copy-of select="$att" copy-namespaces="no"/>
      </xsl:for-each-group>
      <xsl:sequence select="$mergeable-atts[not(self::idml2xml:attribute)]"/>
    </xsl:variable>
    <xsl:comment select="@Self"/>
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

  <xsl:template match="*[name() = $idml2xml:shape-element-names]/@Self" mode="idml2xml:XML-Hubformat-add-properties" priority="4">
    <idml2xml:attribute name="{name()}">
      <xsl:value-of select="."/>
    </idml2xml:attribute>
  </xsl:template>
    
  <xsl:template match="*[name() = $idml2xml:shape-element-names]" mode="idml2xml:XML-Hubformat-add-properties_" priority="4">
    <xsl:copy>
      <xsl:copy-of select="@Self"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:variable name="src-dir-uri-regex" as="xs:string" 
    select="replace($src-dir-uri, '^file:/+', '^file:/+')"/>
  
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

  <xsl:template match="prop/@type" mode="idml2xml:XML-Hubformat-add-properties" as="node()*">
    <xsl:param name="val" as="node()" tunnel="yes" />
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
          <xsl:when test="matches($val, '^Color')">
            <idml2xml:attribute name="{$target-name}">
              <xsl:apply-templates select="key('idml2xml:color', $val, root($val))" mode="#current" >
                <!-- UnderlineColor has its tint value as a number in ../../@UnderlineTint,
                  while other Colors are tinted by means of a Tint element -->
                <xsl:with-param name="multiplier" select="if (matches(($val/name(),'')[1], '(Stroke|Underline)Color')) 
                                                          then number(($val/(../.., ..)/@*[name() = replace($val/name(), 'Color', 'Tint')], 100)[1]) * 0.01
                                                          else 1.0"/>
              </xsl:apply-templates>
            </idml2xml:attribute>
          </xsl:when>
          <xsl:when test="matches($val, '^Tint')">
            <xsl:variable name="tint-decl" select="key('idml2xml:tint', $val, root($val))" as="element(Tint)" />
            <idml2xml:attribute name="{$target-name}">
              <xsl:apply-templates select="key(
                                             'idml2xml:color',
                                             $tint-decl/@BaseColor,
                                             root($val)
                                           )" mode="#current" />
            </idml2xml:attribute>
            <xsl:apply-templates select="$tint-decl/@TintValue" mode="#current" />
          </xsl:when>
          <!-- no color in any case for FillColor="Swatch/..."? -->
          <xsl:when test="matches($val, '^Swatch/None')">
            <idml2xml:remove-attribute name="{../@target-name}" />
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

      <xsl:when test=". eq 'lang'">
        <idml2xml:attribute name="{../@target-name}">
          <!-- provisional -->
          <xsl:value-of select="if (matches($val, 'German') or matches($val, '\Wde\W'))
                                then 'de'
                                else 
                                  if (matches($val, 'English'))
                                  then 'en'
                                  else
                                    if (matches($val, 'Arabic'))
                                    then 'ar'
                                    else
                                      if ($val = '[No Language]')
                                      then ''
                                      else $val" />
        </idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'length'">
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="idml2xml:pt-length($val)" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'linear'">
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="$val" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'list-type-declaration'">
        <xsl:choose>
          <xsl:when test="$val = 'NoList'">
            <idml2xml:attribute name="{name($val)}">NoList</idml2xml:attribute>
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

      <xsl:when test=". eq 'passthru'">
        <idml2xml:attribute name="{../@name}"><xsl:value-of select="$val" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'percentage'">
        <idml2xml:attribute name="{../@target-name}">
          <xsl:value-of select="if ($val castable as xs:integer and xs:integer($val) eq -1) then 1 else round(xs:double($val)*100) * 0.0001" />
        </idml2xml:attribute>
      </xsl:when>
      
      <xsl:when test=". eq 'position'">
        <xsl:choose>
          <xsl:when test="$val eq 'Normal'" />
          <xsl:otherwise>
            <idml2xml:wrap element="{lower-case($val)}" />
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
    <xsl:choose>
      <xsl:when test="
        not($char-elt) 
        or ( 
          $is-unicode
          and $char-elt/@BulletCharacterValue = '8226'
        )">
        <xsl:sequence select="'disc'"/>
      </xsl:when>
      <xsl:when test="$is-unicode and $char-elt/@BulletCharacterValue = ('8211', '8212', '8722')"><!-- U+2013, U+2014, U+2212 -->
        <xsl:sequence select="'dash'"/>
      </xsl:when>
      <xsl:when test="$is-unicode and $char-elt/@BulletCharacterValue = ('10003')"><!-- U+2713 -->
        <xsl:sequence select="'check'"/>
      </xsl:when>
      <xsl:when test="$is-unicode and $char-elt/@BulletCharacterValue = ('9702')"><!-- U+25E6 -->
        <xsl:sequence select="'circle'"/>
      </xsl:when>
      <xsl:when test="$is-unicode and $char-elt/@BulletCharacterValue = ('9670')"><!-- U+25C6 -->
        <xsl:sequence select="'diamond'"/>
      </xsl:when>
      <xsl:when test="$is-unicode and $char-elt/@BulletCharacterValue = ('9725')"><!-- U+25FD -->
        <xsl:sequence select="'box'"/>
      </xsl:when>
      <xsl:when test="$is-unicode and $char-elt/@BulletCharacterValue = ('9726')"><!-- U+25FE -->
        <xsl:sequence select="'square'"/>
      </xsl:when>
      <xsl:when test="$is-unicode and $char-elt/@BulletCharacterValue">
        <xsl:sequence select='concat("&apos;", codepoints-to-string($char-elt/@BulletCharacterValue), "&apos;")' />    
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select='concat("&apos;", $styled-element/@BulletChar, "&apos;")' />    
      </xsl:otherwise>
    </xsl:choose>
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
    <xsl:sequence select="string-join(('#', for $c in $tinted return letex:pad(letex:dec-to-hex($c), 2)), '')"/>
  </xsl:function>

  <xsl:template match="TabList/ListItem" mode="idml2xml:XML-Hubformat-add-properties" as="element(dbk:tab)">
    <tab>
      <xsl:apply-templates mode="#current" />
    </tab>
  </xsl:template>

  <xsl:template match="idPkg:Styles | idPkg:Graphic | idml2xml:hyper | idml2xml:lang | idml2xml:cond" mode="idml2xml:XML-Hubformat-add-properties" />

  <xsl:template match="PageReference" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:copy-of select="." />
  </xsl:template>

  <xsl:key name="idml2xml:style" 
    match="CellStyle | CharacterStyle | ObjectStyle | ParagraphStyle | TableStyle" 
    use="idml2xml:StyleNameEscape(@Self)" />

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-properties2atts -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="* | @*" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:variable name="atts" as="attribute(*)*">
      <xsl:apply-templates select="idml2xml:attribute[not(@name = following-sibling::idml2xml:remove-attribute/@name)]" mode="#current" />
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
          <xsl:sequence select="$content"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="exists(idml2xml:wrap) and empty(self::dbk:style | self::css:rule)">
        <xsl:sequence select="idml2xml:wrap($content, (idml2xml:wrap))" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:sequence select="@*, $content" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
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

  <xsl:template match="idml2xml:attribute[@name = ('css:background-color', 'css:color')]" mode="idml2xml:XML-Hubformat-properties2atts">
    <!-- Even if we’re processing local override colors here: 
         a fill tint that comes from a style has to be applied here. 
         If it isn’t superseded by a local override tint, of course. -->
    <xsl:variable name="style" select="key('idml2xml:css-rule-by-name', 
                                           ../idml2xml:attribute[matches(@name, '^aid5?:(cell|table|[cp])style$')])"
                  as="element(css:rule)?"/>
	<xsl:variable name="last-fill-tint" select="(($style | ..)/idml2xml:attribute[@name = ('fill-tint','fill-value')])[last()]" as="element(idml2xml:attribute)?" />    <xsl:variable name="tinted" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches(., '^device-cmyk')">
        <xsl:sequence select="idml2xml:tint-color(., ($last-fill-tint, 1.0)[1])" />
      </xsl:when>
        <xsl:when test="matches(., '^#[\da-f]{6}$', 'i')">
          <xsl:sequence
            select="idml2xml:tint-dec-rgb-triple(
                                for $i in (letex:rgb-string-to-dec-triple(.)) return number($i), 
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
    <xsl:attribute name="{@name}" select="$tinted" />
  </xsl:template>
  <xsl:template match="idml2xml:attribute[@name = ('fill-tint','fill-value')]" mode="idml2xml:XML-Hubformat-properties2atts"/>
  
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
    <xsl:attribute name="hub:numbering-picture-string" select="../idml2xml:attribute[@name eq 'numbering-expression'][last()]"/>
    <xsl:if test="not(../idml2xml:attribute[@name eq 'numbering-starts-at'][last()] = '1')">
      <xsl:attribute name="hub:numbering-starts-at" select="../idml2xml:attribute[@name eq 'numbering-starts-at'][last()]"/>
    </xsl:if>
    <xsl:attribute name="hub:numbering-level" select="../idml2xml:attribute[@name eq 'numbering-level'][last()]"/>
    <xsl:if test="../idml2xml:attribute[@name eq 'numbering-continue'][last()] = 'true'">
      <xsl:attribute name="hub:numbering-continue" select="../idml2xml:attribute[@name eq 'numbering-continue'][last()]"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template mode="idml2xml:XML-Hubformat-properties2atts" priority="2" 
    match="idml2xml:attribute[@name = ('numbering-starts-at', 'numbering-format', 'numbering-expression', 'numbering-continue', 'numbering-level')]" />
  
  <xsl:function name="idml2xml:numbered-list-style-type" as="xs:string">
    <xsl:param name="type-example-string" as="xs:string"/>
    <xsl:param name="picture-string" as="xs:string"/>
    <xsl:param name="level" as="xs:string"/>
    <!-- §§§ Please note that the picture string does not influence the result.
         This is partly due do CSS3 lists not supporting interpunction and
         inclusion of upper levels in a straightforward declarative way -->
    <xsl:choose>
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
                        [.//idml2xml:genFrame[idml2xml:same-scope(., current())]]" mode="idml2xml:XML-Hubformat-extract-frames">
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

  <xsl:template match="/*/idml2xml:genFrame (: unanchored frames :)" mode="idml2xml:XML-Hubformat-extract-frames">
    <xsl:apply-templates select="descendant-or-self::idml2xml:genFrame[idml2xml:same-scope(., current())]"  mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
  </xsl:template>

  <xsl:function name="idml2xml:text-after" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:param name="ancestor" as="element(*)" />
    <xsl:sequence select="matches(
                            string-join(
                              $ancestor//text()[. &gt;&gt; $elt] 
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
       throwing away the figure caption in case of Hogrefe 101026_02142_FPT Abbildung 1. §§§ Create a test case -->
  <xsl:template match="idml2xml:genFrame[ancestor::idml2xml:genFrame[@idml2xml:elementName eq 'Group'][*/@aid:cstyle]]" 
    mode="idml2xml:XML-Hubformat-extract-frames">
    <idml2xml:genAnchor xml:id="{generate-id()}"/>
    <xsl:apply-templates select="." mode="idml2xml:XML-Hubformat-extract-frames-genFrame"/>
  </xsl:template>
  

  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames-genFrame">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="linkend" select="generate-id()" />
      <xsl:apply-templates mode="idml2xml:XML-Hubformat-extract-frames" />
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="idml2xml:XML-Hubformat-extract-frames-genFrame idml2xml:XML-Hubformat-extract-frames" priority="3"
    match="idml2xml:genFrame[not(node())]" />


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-remap-para-and-span -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:variable name="id-prefix" select="'id_'" as="xs:string"/>

  <xsl:template match="idml2xml:genPara" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:element name="para">
      <xsl:if test="@aid:pstyle">
	      <xsl:attribute name="role" select="idml2xml:StyleName( @aid:pstyle )" />
      </xsl:if>
      <xsl:apply-templates select="@* except @aid:pstyle" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
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
                         )
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
        <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        <xsl:apply-templates select="node() except idml2xml:genAnchor" mode="#current"/>
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

  <xsl:template match="@linkend" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="linkend" select="concat ($id-prefix, idml2xml:normalize-name(.))" />
  </xsl:template>
  
  <xsl:template match="@aid:cstyle" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="role" select="." />
  </xsl:template>

  <xsl:template match="idml2xml:genFrame" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <sidebar remap="{@idml2xml:elementName}">
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </sidebar>
  </xsl:template>

  <xsl:template match="@idml2xml:objectstyle" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="role" select="idml2xml:StyleName(.)"/>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[ not( descendant::node()[self::text()] ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"
		priority="-1">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>


<!--  <xsl:template match="idml2xml:CharacterStyleRange[ ( idml2xml:Br  and  count(*) eq 1 )  or  
		       ( idml2xml:Br  and  idml2xml:Content 	and  not( idml2xml:Content/node() )
		       and count(*) eq 2 ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:if test="not( following::*[1][ self::idml2xml:ParagraphStyleRange ] )">
      <xsl:apply-templates mode="#current"/>
    </xsl:if>
  </xsl:template>-->

  <xsl:template match="PageReference" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <!-- Convert to an indexterm here for general projects and set specific @xml:id for 
         "indexterms" initial template (will export the indexterms in a separate pass). -->
    <indexterm xml:id="ie_{$idml2xml:basename}_{@Self}">
      <xsl:for-each select="tokenize( if(@idml2xml:ReferencedTopic) then @idml2xml:ReferencedTopic else @ReferencedTopic, '(d1)?Topicn' )">
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

  <!-- §§§ does this still work? -->
  <xsl:template match="HiddenText[matches((.//@condition)[1], 'PageStart')]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor xml:id="{replace(., '^.*_(.+)$', 'page_$1')}"/>
  </xsl:template>

  <xsl:template match="HiddenText[matches((.//@condition)[1], 'PageEnd')]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor xml:id="{replace(., '^.*_(.+)$', 'pageend_$1')}"/>
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
    match="@idml2xml:* " 
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

  <xsl:template match="idml2xml:genTable" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="head-count" select="number(@idml2xml:header-row-count)"/>
    <informaltable>
      <xsl:attribute name="role" select="idml2xml:StyleName(@aid5:tablestyle)"/>
      <xsl:apply-templates select="@css:* | @xml:* | @srcpath" mode="#current"/>
      <tgroup>
        <xsl:attribute name="cols" select="@aid:tcols"/>
        <xsl:apply-templates select="Column" mode="#current"/>
        <xsl:if test="number(@idml2xml:header-row-count) gt 0">
          <thead>
            <xsl:for-each-group select="idml2xml:genCell[number(@idml2xml:rowname) lt $head-count]" group-by="@idml2xml:rowname">
              <xsl:call-template name="idml2xml:row" />
            </xsl:for-each-group>
          </thead>
        </xsl:if>
        <tbody>
          <xsl:for-each-group select="idml2xml:genCell[number(@idml2xml:rowname) gt ($head-count - 1)]" group-by="@idml2xml:rowname">
            <xsl:call-template name="idml2xml:row" />
          </xsl:for-each-group>
        </tbody>
      </tgroup>
    </informaltable>
  </xsl:template>

  <xsl:template name="idml2xml:row" as="element(dbk:row)*">
    <row>
      <xsl:for-each select="current-group()">
        <entry>
          <xsl:apply-templates select="@xml:*, @css:*" mode="#current"/>
          <xsl:variable name="col" select="xs:integer(@idml2xml:colname)+1" as="xs:integer"/>
          <xsl:variable name="colspan" select="xs:integer(@aid:ccols)" as="xs:integer"/>
          <xsl:choose>
            <xsl:when test="number(@aid:ccols) gt 1">
              <xsl:attribute name="namest" select="concat('c',$col)"/>
              <xsl:attribute name="nameend" select="concat('c',$col + $colspan - 1)"/>
              <xsl:attribute name="css:width" 
                select="idml2xml:pt-length(string(sum(../Column/@SingleColumnWidth[position() = ($col to $col + $colspan - 1)])))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="colname" select="concat('c',number(@idml2xml:colname)+1)"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="number(@aid:crows) gt 1">
            <xsl:attribute name="morerows" select="number(@aid:crows)-1"/>
          </xsl:if>
          <xsl:attribute name="role" select="idml2xml:StyleName(@aid5:cellstyle)"/>
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


  <!-- figures -->
  <xsl:template match="*[name() = $idml2xml:shape-element-names][not(@idml2xml:rectangle-embedded-source='true')][Image or EPS or PDF or WMF]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span" priority="2">
    <xsl:variable name="identical-Self-objects" select="key('idml2xml:by-Self', @Self)" as="element(*)+" />
    <xsl:variable name="my-number" as="xs:integer"
      select="index-of(for $o in $identical-Self-objects return generate-id($o), generate-id(.))" />
    <xsl:variable name="suffix" as="xs:string"
      select="letex:identical-self-object-suffix(.)"/>
    <xsl:variable name="image-info" as="element(image)">
      <xsl:apply-templates select="." mode="idml2xml:Images"/>
    </xsl:variable>
    <mediaobject css:width="{$image-info/@shape-width}" css:height="{$image-info/@shape-height}">
      <xsl:apply-templates select="@idml2xml:objectstyle" mode="#current"/>
      <imageobject>
        <imagedata fileref="{.//@LinkResourceURI}" xml:id="img_{$idml2xml:basename}_{@Self}{$suffix}" css:width="{$image-info/@width}px" css:height="{$image-info/@height}px"/>
      </imageobject>
    </mediaobject>
  </xsl:template>

  <xsl:template match="*[name() = $idml2xml:shape-element-names][not(@idml2xml:keep-object eq 'true')]" mode="idml2xml:XML-Hubformat-remap-para-and-span"/>

  <xsl:template match="*[name() = $idml2xml:shape-element-names][@idml2xml:keep-object eq 'true']" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:next-match/><!-- identity -->
  </xsl:template>
  
  <!-- footnotes -->
  <xsl:template match="Footnote" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <footnote>
      <xsl:apply-templates mode="#current"/>
    </footnote>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[*[name() = $idml2xml:shape-element-names]]"
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
      </xsl:if>
      <xsl:apply-templates select="@* except @aid:pstyle, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-cleanup-paras-and-br -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  <xsl:template match="text()" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:value-of select="replace(., '&#xfeff;', '')"/>
  </xsl:template>


  <xsl:template match="@css:text-decoration-width[../@css:text-decoration-line = 'none']"
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  <xsl:template match="@css:text-decoration-offset[../@css:text-decoration-line = 'none']"
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  <xsl:template match="@css:text-decoration-color[../@css:text-decoration-line = 'none']"
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>
  
  <xsl:template match="dbk:superscript
                         [dbk:footnote]
                         [every $c in (text()[normalize-space()], *) 
                          satisfies ($c/self::dbk:footnote)]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <phrase>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </phrase>
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
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <!-- Links around unanchored mediaobjects may occur on the top level --> 
  <xsl:template match="*[self::dbk:mediaobject or self::dbk:link][not(parent::dbk:para or parent::dbk:phrase or parent::dbk:link)]" 		
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" priority="2">
    <xsl:element name="para">
      <xsl:next-match/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="dbk:mediaobject[(some $n in ancestor::dbk:para[1]//text() satisfies (matches($n, '\S')))
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
      match="*[local-name() ne '' and not( name() = ($hubformat-elementnames-whitelist, tokenize($hub-other-elementnames-whitelist,',')) )]" 
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

  <!-- Make @role and css:rule/@name compliant with the rules for CSS identifiers
       http://www.w3.org/TR/CSS21/syndata.html#characters --> 

  <xsl:template match="@role[not($hub-version eq '1.0')] | css:rule/@name | dbk:linked-style/@name" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:attribute name="{name()}" 
      select="replace(replace(replace(., '[^_~&#x2dc;a-zA-Z0-9-]', '_'), '[~&#x2dc;]', '_-_'), '^(\I)', '_$1')"/>
    <!-- [~˜] is treated as a special character: by convention, typesetters may add style variants
        that should be treated equivalently by adding a tilde, followed by arbitrary name components -->
  </xsl:template>

  <!-- for finding sidebar[@linkend] to a given anchor[@xml:id]: -->
  <xsl:key name="idml2xml:linking-item-by-id" match="*[@linkend]" use="@linkend" />
  <!-- for finding anchor[@xml:id] to a given sidebar[@linkend]: -->
  <xsl:key name="idml2xml:linking-item-by-linkend" match="*[@*:id]" use="@*:id" />
  
  <!-- Replace anchors in groups with the items that they point to (typically, sidebar of the TextFrame type,
       or Rectangles) --> 
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

</xsl:stylesheet>
