<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
    version="2.0"
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs = "http://www.w3.org/2001/XMLSchema"
    xmlns:xhtml = "http://www.w3.org/1999/xhtml"
    xmlns:css="http://www.w3.org/1996/css"
    xmlns:aid = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5 = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml = "http://www.le-tex.de/namespace/idml2xml"
    xmlns:xlink = "http://www.w3.org/1999/xlink"
    xmlns:dbk = "http://docbook.org/ns/docbook"
    xmlns="http://docbook.org/ns/docbook"
    >

  <!-- 
       xmlns:hub	= "http://www.le-tex.de/namespace/hubformat"
       xmlns="http://www.le-tex.de/namespace/hubformat"
  -->

  <xsl:import href="../propmap.xsl"/>

  <xsl:variable 
      name="hubformat-elementnames-whitelist"
      select="('anchor', 'book', 'Body', 'para', 'info', 'informaltable', 'table', 'tgroup', 
               'colspec', 'tbody', 'row', 'entry', 'mediaobject', 'tab', 'tabs', 'br',
               'imageobject', 'imagedata', 'phrase', 'emphasis', 'sidebar',
               'superscript', 'subscript', 'link', 'xref', 'footnote',
               'keywordset', 'keyword', 'indexterm', 'primary', 'secondary', 'tertiary',
               'see', 'seealso',
               'styles', 'parastyles', 'inlinestyles', 'objectstyles', 'cellstyles', 'tablestyles', 'style', 'thead' 
              )"/>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-add-properties -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- see ../propmap.xsl -->

  <xsl:template match="idml2xml:doc" mode="idml2xml:XML-Hubformat-add-properties">
    <Body xmlns="http://docbook.org/ns/docbook" version="5.1-variant le-tex_Hub-1.0" css:version="3.0-variant le-tex_Hub-1.0">
      <info>
        <keywordset role="hub">
          <keyword role="source-basename"><xsl:value-of select="$idml2xml:basename"/></keyword>
          <keyword role="source-dir-uri"><xsl:value-of select="$src-dir-uri"/></keyword>
          <keyword role="source-paths"><xsl:value-of select="if ($srcpaths = 'yes') then 'true' else 'false'"/></keyword>
          <keyword role="formatting-deviations-only">true</keyword>
          <keyword role="source-type">idml</keyword>
          <xsl:if test="/*/@TOCStyle_Title">
            <keyword role="toc-title">
              <xsl:value-of select="/*/@TOCStyle_Title"/>
            </keyword>
          </xsl:if>
        </keywordset>
        <styles>
          <parastyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid:pstyle) return concat('ParagraphStyle', '/', idml2xml:StyleNameEscape($s)))" mode="#current">
              <xsl:sort select="@Name" />
            </xsl:apply-templates>
          </parastyles>
          <inlinestyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid:cstyle) return concat('CharacterStyle', '/', idml2xml:StyleNameEscape($s)))" mode="#current">
              <xsl:sort select="@Name" />
            </xsl:apply-templates>
          </inlinestyles>
          <tablestyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid5:tablestyle) return concat('TableStyle', '/', idml2xml:StyleNameEscape($s)))" mode="#current">
              <xsl:sort select="@Name" />
            </xsl:apply-templates>

          </tablestyles>
          <cellstyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid5:cellstyle) return concat('CellStyle', '/', idml2xml:StyleNameEscape($s)))" mode="#current" >
              <xsl:sort select="@Name" />
            </xsl:apply-templates>
          </cellstyles>
        </styles>
      </info>
      <xsl:apply-templates mode="#current"/>
    </Body>
  </xsl:template>

  <xsl:template match="ParagraphStyle | CharacterStyle | TableStyle | CellStyle" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:param name="wrap-in-style-element" select="true()" as="xs:boolean"/>
    <xsl:variable name="atts" as="node()*">
      <xsl:apply-templates select="if (Properties/BasedOn) 
                                   then key('idml2xml:style', Properties/BasedOn) 
                                   else ()" mode="#current">
        <xsl:with-param name="wrap-in-style-element" select="false()"/>
      </xsl:apply-templates>
      <xsl:variable name="mergeable-atts" as="element(*)*">
        <xsl:apply-templates select="@*, Properties/*[not(self::BasedOn)]" mode="#current" />
      </xsl:variable>
      <xsl:for-each-group select="$mergeable-atts[self::idml2xml:attribute]" group-by="@name">
        <idml2xml:attribute name="{current-grouping-key()}"><xsl:value-of select="current-group()" /></idml2xml:attribute>
      </xsl:for-each-group>
      <xsl:sequence select="$mergeable-atts[not(self::idml2xml:attribute)]"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$wrap-in-style-element">
        <style role="{idml2xml:StyleName(@Name)}">
          <xsl:sequence select="$atts"/>
        </style>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$atts"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Properties" mode="idml2xml:XML-Hubformat-add-properties">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  <xsl:template match="Properties/BasedOn" mode="idml2xml:XML-Hubformat-add-properties" />


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
<!--     <xsl:apply-templates select="$raw-output" mode="idml2xml:XML-Hubformat-add-properties2"/> -->
  </xsl:template>

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-add-properties">
    <idml2xml:attribute name="srcpath"><xsl:value-of select="substring-after(., replace($src-dir-uri, '^file:/+', 'file:/'))" /></idml2xml:attribute>
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

      <xsl:when test=". eq 'color'">
        <xsl:variable name="context-name" select="$val/../name()" as="xs:string" />
        <xsl:variable name="target-name" select="(../context[matches($context-name, @match)]/@target-name, ../@target-name)[1]" as="xs:string" />
        <xsl:choose>
          <xsl:when test="matches($val, '^Color')">
            <idml2xml:attribute name="{$target-name}">
              <xsl:apply-templates select="key('idml2xml:color', $val, root($val))" mode="#current" />
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

      <xsl:when test=". eq 'percentage'">
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="if (xs:integer($val) eq -1) then 1 else xs:double($val) * 0.01" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'lang'">
        <idml2xml:attribute name="{../@target-name}">
          <!-- provisional -->
          <xsl:value-of select="if (matches($val, 'German') or matches($val, '\Wde\W'))
                                then 'de'
                                else 
                                  if (matches($val, 'English'))
                                  then 'en'
                                  else $val" />
        </idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'length'">
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="idml2xml:pt-length($val)" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'linear'">
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="$val" /></idml2xml:attribute>
      </xsl:when>

      <xsl:when test=". eq 'passthru'">
        <idml2xml:attribute name="{../@name}"><xsl:value-of select="$val" /></idml2xml:attribute>
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
        <idml2xml:style-link type="{../@name}" target="{idml2xml:StyleName($val)}"/>
      </xsl:when>

      <xsl:when test=". eq 'tablist'">
        <tabs>
          <xsl:apply-templates select="$val/*" mode="#current"/>
        </tabs>
      </xsl:when>

      <xsl:otherwise>
        <idml2xml:attribute name="{../@target-name}"><xsl:value-of select="$val" /></idml2xml:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

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
      <xsl:otherwise>
        <xsl:message>Unknown colorspace <xsl:value-of select="@Space"/>
        </xsl:message>
        <xsl:sequence select="@ColorValue" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="TabList/ListItem" mode="idml2xml:XML-Hubformat-add-properties" as="element(dbk:tab)">
    <tab>
      <xsl:apply-templates mode="#current" />
    </tab>
  </xsl:template>

  <xsl:template match="idPkg:Styles | idPkg:Graphic | idml2xml:hyper | idml2xml:lang" mode="idml2xml:XML-Hubformat-add-properties" />

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
    <xsl:variable name="content" as="node()*">
      <xsl:apply-templates select="idml2xml:style-link" mode="#current" />
      <xsl:apply-templates select="idml2xml:attribute[not(@name = following-sibling::idml2xml:remove-attribute/@name)]" mode="#current" />
      <xsl:apply-templates select="node() except (idml2xml:attribute | idml2xml:wrap | idml2xml:style-link)" mode="#current" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="exists(idml2xml:wrap) and exists(self::dbk:style)">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:attribute name="remap" select="idml2xml:wrap/@element" />
        </xsl:copy>
      </xsl:when>
      <xsl:when test="exists(idml2xml:wrap) and not(self::dbk:style)">
        <xsl:sequence select="idml2xml:wrap($content, (idml2xml:wrap))" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:sequence select="@*, $content" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
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

  <xsl:template match="idml2xml:attribute" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:attribute name="{@name}" select="." />
  </xsl:template>

  <xsl:template match="idml2xml:attribute[@name = ('css:background-color', 'css:color')]" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:variable name="last-fill-tint" select="../idml2xml:attribute[@name = ('fill-tint','fill-value')][last()]" as="element(idml2xml:attribute)?" />
    <xsl:attribute name="{@name}" select="idml2xml:tint-color(., ($last-fill-tint, 1.0)[1])" />
  </xsl:template>

  <xsl:template match="idml2xml:attribute[@name = ('fill-tint','fill-value')]" mode="idml2xml:XML-Hubformat-properties2atts"/>

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

  <xsl:template match="idml2xml:remove-attribute" mode="idml2xml:XML-Hubformat-properties2atts" />

  <xsl:template match="idml2xml:style-link" mode="idml2xml:XML-Hubformat-properties2atts">
    <xsl:attribute name="{if (@type eq 'AppliedParagraphStyle')
                          then 'parastyle'
                          else @type}" 
      select="@target" />
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


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-extract-frames -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="*[@aid:pstyle][.//idml2xml:genFrame[idml2xml:same-scope(., current())]]" mode="idml2xml:XML-Hubformat-extract-frames">
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
                            string-join($ancestor//text()[. &gt;&gt; $elt] except $ancestor//idml2xml:genFrame//text(), ''),
                            '\S'
                          )" />
  </xsl:function>

  <xsl:template match="idml2xml:genFrame" mode="idml2xml:XML-Hubformat-extract-frames">
    <idml2xml:genAnchor xml:id="{generate-id()}"/>
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
      <xsl:attribute name="role" select="idml2xml:StyleName( @aid:pstyle )" />
      <xsl:apply-templates select="@* except @aid:pstyle" mode="#current"/>
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
    <xsl:variable name="role" select="idml2xml:StyleName( (@aid:cstyle, '')[1] )"/>
    <xsl:choose>
      <xsl:when test="$role eq 'No_character_style' 
                      and not(text()[matches(., '\S')]) 
                      and count(*) gt 0 and 
                      count(*) eq count(PageReference union HyperlinkTextSource)">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:when test="$role eq 'No_character_style' 
                      and not(text()[matches(., '\S')]) 
                      and count(* except idml2xml:genAnchor) eq 0">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:when test="$role eq 'No_character_style' 
                      and text() 
                      and count(* except idml2xml:genAnchor) eq 0
                      and count(@* except (@aid:cstyle union @srcpath union @idml2xml:*)) eq 0
                      ">
        <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        <xsl:apply-templates select="node() except idml2xml:genAnchor" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="idml2xml:genAnchor">
          <xsl:apply-templates select="idml2xml:genAnchor" mode="#current"/>
        </xsl:if>
        <phrase>
          <xsl:if test="$role ne ''">
            <xsl:attribute name="role" select="$role"/>
          </xsl:if>
          <xsl:variable name="atts" select="@* except (@aid:cstyle union @srcpath union @idml2xml:*)" as="attribute(*)*" />
          <xsl:apply-templates select="@srcpath, $atts, node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
        </phrase>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="idml2xml:link" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:choose>
      <xsl:when test="matches(@idml2xml:href,'(end)?page')">
        <anchor xml:id="{@idml2xml:href}" />
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

  <xsl:template match="idml2xml:genAnchor" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor xml:id="{$id-prefix}{@*:id}" />
  </xsl:template>

  <xsl:template match="@linkend" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:attribute name="linkend" select="concat ($id-prefix, .)" />
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

  <xsl:template match="idml2xml:genSpan[ not( descendant::node()[self::text()] ) ]" 
		mode="idml2xml:XML-Hubformat-remap-para-and-span"
		priority="-1">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="TextVariableInstance" mode="idml2xml:XML-Hubformat-remap-para-and-span"/>


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

  <xsl:template match="HiddenText[matches(.//@*:AppliedConditions, 'Condition/PageStart')]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor xml:id="page_{replace(string-join(.//text(),''), '^.*_(\d+)$', '$1')}"/>
  </xsl:template>

  <xsl:template match="HiddenText[matches(.//@*:AppliedConditions, 'Condition/PageEnd')]" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <anchor xml:id="pageend_{replace(string-join(.//text(),''), '^.*_(\d+)$', '$1')}"/>
  </xsl:template>
  
  <xsl:template match="idml2xml:parsep"
    mode="idml2xml:XML-Hubformat-remap-para-and-span" />

  <xsl:template match="idml2xml:tab" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <tab>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </tab>
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

  <xsl:template 
    match="@idml2xml:* " 
    mode="idml2xml:XML-Hubformat-remap-para-and-span" 
    />

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-remap-para-and-span" >
    <xsl:copy-of select="." />
  </xsl:template>


  <!-- BEGIN: tables -->

  <xsl:template match="idml2xml:genTable" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="head-count" select="number(@idml2xml:header-row-count)"/>
    <informaltable>
      <tgroup>
        <xsl:attribute name="cols" select="@aid:tcols"/>
        <xsl:for-each select="1 to xs:integer(@aid:tcols)">
          <colspec>
            <xsl:attribute name="colname" select="concat('c',position())"/>
          </colspec>
        </xsl:for-each>
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
          <xsl:choose>
            <xsl:when test="number(@aid:ccols) gt 1">
              <xsl:attribute name="namest" select="concat('c',number(@idml2xml:colname)+1)"/>
              <xsl:attribute name="nameend" select="concat('c',number(@idml2xml:colname)+number(@aid:ccols))"/>
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
  <xsl:template match="Rectangle[not(@idml2xml:rectangle-embedded-source='true')][Image or EPS or PDF or WMF]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <mediaobject>
      <imageobject>
        <imagedata fileref="{.//@LinkResourceURI}"/>
      </imageobject>
    </mediaobject>
  </xsl:template>

  <xsl:template match="Rectangle" mode="idml2xml:XML-Hubformat-remap-para-and-span"/>


  <!-- footnotes -->
  <xsl:template match="Footnote" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <footnote>
      <xsl:apply-templates mode="#current"/>
    </footnote>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[Rectangle]"
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
  <xsl:template match="*[local-name() = tokenize($hub-other-elementnames-whitelist,',') and not(.//idml2xml:genFrame[idml2xml:same-scope(., current())])]" 
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

  <xsl:template match="dbk:superscript
                         [dbk:footnote]
                         [every $c in (text()[normalize-space()], *) 
                          satisfies ($c/self::dbk:footnote)]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <phrase>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </phrase>
    <xsl:apply-templates mode="#current"/>
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
  <xsl:template match="dbk:phrase[count(node()) eq count(dbk:informaltable)]" 		
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="dbk:mediaobject[not(parent::dbk:para or parent::dbk:phrase)]" 		
    mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <para>
      <xsl:next-match/>
    </para>
  </xsl:template>


  <xsl:template match="dbk:para[parent::dbk:para]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <phrase role="idml2xml-para {@role}">
      <xsl:apply-templates select="@* except @role | node()" mode="#current"/>
    </phrase>
  </xsl:template>

  <xsl:template 
      match="@*:AppliedParagraphStyle | @*:AppliedCharacterStyle" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" />

  <xsl:template 
      match="node()[local-name() ne '' and not( local-name() = ($hubformat-elementnames-whitelist, tokenize($hub-other-elementnames-whitelist,',')) )]" 
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

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-without-srcpath -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-without-srcpath" />


</xsl:stylesheet>
