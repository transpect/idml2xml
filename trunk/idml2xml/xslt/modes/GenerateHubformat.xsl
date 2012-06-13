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
               'styles', 'parastyles', 'inlinestyles', 'objectstyles', 'cellstyles', 'tablestyles', 'style'
              )"/>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-add-properties -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- see ../propmap.xsl -->

  <xsl:template match="idml2xml:doc" mode="idml2xml:XML-Hubformat-add-properties">
    <Body xmlns="http://docbook.org/ns/docbook" version="5.1-variant le-tex_Hub-1.0" css:version="3.0-variant le-tex_Hub-1.0">
      <info>
        <keywordset role="hub">
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
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid:pstyle) return concat('ParagraphStyle', '/', $s))" mode="#current">
              <xsl:sort select="@Name" />
            </xsl:apply-templates>
          </parastyles>
          <inlinestyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid:cstyle) return concat('CharacterStyle', '/', $s))" mode="#current">
              <xsl:sort select="@Name" />
            </xsl:apply-templates>
          </inlinestyles>
          <tablestyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid5:tablestyle) return concat('TableStyle', '/', $s))" mode="#current">
              <xsl:sort select="@Name" />
            </xsl:apply-templates>

          </tablestyles>
          <cellstyles>
            <xsl:apply-templates select="key('idml2xml:style', for $s in distinct-values(//*/@aid5:cellstyle) return concat('CellStyle', '/', $s))" mode="#current" >
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

  <xsl:key name="idml2xml:style" 
    match="CellStyle | CharacterStyle | ObjectStyle | ParagraphStyle | TableStyle" 
    use="@Self" />

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
      <xsl:when test="exists(idml2xml:wrap) and not(self::style)">
        <xsl:sequence select="idml2xml:wrap($content, (idml2xml:wrap))" />
      </xsl:when>
      <xsl:when test="exists(idml2xml:wrap) and exists(self::style)">
        <xsl:attribute name="wrap" select="@element" />
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
    <xsl:variable name="last-fill-tint" select="../idml2xml:attribute[@name = 'fill-tint'][last()]" as="element(idml2xml:attribute)?" />
    <xsl:attribute name="{@name}" select="idml2xml:tint-color(., ($last-fill-tint, 1.0)[1])" />
  </xsl:template>

  <xsl:template match="idml2xml:attribute[@name = ('fill-tint')]" mode="idml2xml:XML-Hubformat-properties2atts"/>

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
          <xsl:choose>
            <xsl:when test="exists($atts)">
              <!--
              <xsl:if test="matches(., '^Tab\.&#xa0;')">
ATTS: <xsl:sequence select="string-join(for $a in $atts return concat(name($a), '=', $a), ', ')"/>
              </xsl:if>
              -->
              <emphasis srcpath="{@srcpath}">
                <xsl:apply-templates select="$atts, node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
              </emphasis>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="@srcpath" />
              <xsl:apply-templates select="node()[not(self::idml2xml:genAnchor)]" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </phrase>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="idml2xml:link" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <link>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </link>
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

  <xsl:template match="idml2xml:tab" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <tab>
      <xsl:apply-templates select="@*" mode="#current" />
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

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-remap-para-and-span" >
    <xsl:copy-of select="." />
  </xsl:template>


  <!-- BEGIN: tables -->

  <!-- doesn't work correctly for nested tables yet (need to restrict selected cells to idml2xml:same-scope cells -->

  <xsl:template match="idml2xml:genPara
                         [*[@aid:table='table']]
                         [every $c in * satisfies ($c[@aid:table='table'])]
                       |
                       idml2xml:genPara
                         [idml2xml:genSpan
                           [*[@aid:table='table']]
                           [every $c in * satisfies ($c[@aid:table='table'])]
                         ]
                         [every $s in * satisfies ($s/self::idml2xml:genSpan)]"
    mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:variable name="table" select="(*[@aid:table='table'], */*[@aid:table='table'])[1]" as="element(*)" />
    <xsl:variable name="var-cols" select="xs:integer($table/@aid:tcols)" as="xs:integer"/>
    <xsl:variable name="var-table" as="element(dbk:row)*">
      <xsl:for-each select="idml2xml:make-rows( 
                              $var-cols, 
                              descendant::*[@aid:table eq 'cell'][1], 
                              number(descendant::*[@aid:table eq 'cell'][1]/@aid:ccols), 
                              0, 
                              'true'
                            )/descendant-or-self::dbk:row">
        <xsl:copy>
          <xsl:sequence select="*[@aid:table eq 'cell']" />
        </xsl:copy>
      </xsl:for-each>
    </xsl:variable>
    <informaltable>
      <tgroup>
        <xsl:attribute name="cols" select="$var-cols" />
        <xsl:for-each select="1 to $var-cols">
          <xsl:element name="colspec">
            <xsl:attribute name="colname" select="concat( 'c', current() )"/>
          </xsl:element>
        </xsl:for-each>
        <xsl:element name="tbody">
          <xsl:apply-templates select="$var-table" mode="#current" />
        </xsl:element>
      </tgroup>
    </informaltable>
  </xsl:template>

  <xsl:template match="*[@aid:table='cell']" mode="idml2xml:XML-Hubformat-remap-para-and-span" as="element(dbk:entry)">
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
      <xsl:attribute name="role" select="@aid5:cellstyle"/>
      <xsl:apply-templates mode="#current"/>
    </entry>
  </xsl:template>
  
  <xsl:function name="idml2xml:make-rows" as="element(dbk:row)*">
    <xsl:param name="var-cols" as="xs:double" />
    <xsl:param name="var-current-cell" as="element()*" />
    <xsl:param name="var-cumulated-cols" as="xs:double" />
    <xsl:param name="var-overlap" as="xs:integer*" />
    <xsl:param name="var-starts" as="xs:string" />
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
    <xsl:if test="($var-current-cell ne '') or exists($var-current-cell/following-sibling::*[@aid:table eq 'cell'])">
      <row>
        <xsl:sequence select="idml2xml:cells2row(
                                $var-cols, 
                                $var-current-cell, 
                                $var-cumulated-overlap + number($var-current-cell/@aid:ccols), 
                                $var-new-overlap
                              )" />
      </row>
    </xsl:if>
  </xsl:function>

  <xsl:function name="idml2xml:cells2row" as="element(*)*"> <!-- cell elements with their original name -->
    <xsl:param name="var-cols" as="xs:double" />
    <xsl:param name="var-current-cell" as="element()*" />
    <xsl:param name="var-cumulated-cols" as="xs:double" />
    <xsl:param name="var-overlap" as="xs:integer*" />
    <xsl:variable name="var-new-overlap" as="xs:integer*"
       select="$var-overlap, 
               if ($var-current-cell/@aid:crows ne '1') 
               then 
                 for $j in 1 to xs:integer($var-current-cell/@aid:ccols)
                 return xs:integer($var-current-cell/@aid:crows)
               else 0" />
    <xsl:choose>
      <xsl:when test="$var-cumulated-cols eq $var-cols">
        <xsl:for-each select="$var-current-cell">
          <xsl:copy>
            <xsl:attribute name="cumulated-cols" select="$var-cumulated-cols" />
            <xsl:copy-of select="@*|node()" />
          </xsl:copy>
        </xsl:for-each>
        <xsl:sequence select="idml2xml:make-rows(
                                $var-cols, 
                                $var-current-cell/following-sibling::*[@aid:table eq 'cell'][1], 
                                number($var-current-cell/following-sibling::*[@aid:table eq 'cell'][1]/@aid:ccols), 
                                $var-new-overlap, 
                                'false'
                              )" />
      </xsl:when>
      <xsl:when test="$var-cumulated-cols lt $var-cols">
        <xsl:for-each select="$var-current-cell">
          <xsl:copy>
            <xsl:attribute name="cumulated-cols" select="$var-cumulated-cols" />
            <xsl:copy-of select="@*|node()" />
          </xsl:copy>
        </xsl:for-each>
        <xsl:sequence select="idml2xml:cells2row(
                                $var-cols, 
                                $var-current-cell/following-sibling::*[@aid:table eq 'cell'][1], 
                                $var-cumulated-cols + number($var-current-cell/following-sibling::*[@aid:table eq 'cell'][1]/@aid:ccols), 
                                $var-new-overlap
                              )" />
      </xsl:when>
      <xsl:when test="$var-cumulated-cols gt $var-cols">
        <xsl:message terminate="no">Error: <xsl:value-of select="$var-cumulated-cols" /> cells in row, but only <xsl:value-of select="$var-cols" /> are allowed.</xsl:message>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <!-- END: tables -->

  <xsl:template match="HyperlinkTextDestination | 
                       HyperlinkTextSource"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>


  <!-- figures -->
  <xsl:template match="Rectangle[not(@idml2xml:rectangle-embedded-source='true')][Image or EPS or PDF]"
		mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <para>
      <mediaobject>
        <imageobject>
          <imagedata fileref="{.//@LinkResourceURI}"/>
        </imageobject>
      </mediaobject>
    </para>
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
  

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-cleanup-paras-and-br -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  <!-- what's this supposed to do? There's no p element (and no dbk:p) here. What if there's text around the phrase? -->
  <xsl:template match="phrase[ parent::p[count(*) eq 1 ] ]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:apply-templates mode="#current"/>
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

  <xsl:template match="dbk:phrase[@role='br'][ following-sibling::*[ self::dbk:para ] ] |
		       dbk:phrase[@role='br'][ not(following-sibling::*) and parent::dbk:para ]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br"/>

  <xsl:template match="dbk:row[not(node())]" 
		mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:message select="'INFO: Removed empty element row.'"/>
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
      match="*[not( local-name() = $hubformat-elementnames-whitelist )]" 
      mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <xsl:variable name="content" select="string-join(.,'')"/>
    <xsl:message>
      INFO: Removed non-hub element <xsl:value-of select="name()"/>
      <xsl:if test="$content ne ''">
        ===
        Text content: <xsl:value-of select="$content"/>
        ===</xsl:if>
    </xsl:message>
  </xsl:template>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: XML-Hubformat-cleanup-paras-and-br -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="@srcpath" mode="idml2xml:XML-Hubformat-without-srcpath" />


</xsl:stylesheet>