<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tr    = "http://transpect.io" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  version="1.0"
  name="idml_single-doc"
  type="idml2xml:single-doc"
  >

  <p:option name="idmlfile" />
  <p:option name="hub-version" required="false" select="'1.2'"/>
  <p:option name="srcpaths" required="false" select="'no'"/>
  <p:option name="all-styles" required="false" select="'no'"/>
  <p:option name="discard-tagging" required="false" select="'no'"/>
  <p:option name="process-embedded-images" required="false" select="'yes'"/>
  <p:option name="hub-other-elementnames-whitelist" required="false" select="''"/>
  <p:option name="output-items-not-on-workspace" required="false" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:input port="xslt-stylesheet">
    <p:document href="../xsl/idml2xml.xsl"/>
  </p:input>
  <p:output port="result" primary="true" >
    <p:pipe step="Document" port="result"/>
  </p:output>
  <p:output port="zip-manifest">
    <p:pipe port="result" step="zip-manifest"/>
  </p:output>
  <p:output port="xslt-params" primary="false">
    <p:pipe step="xslt-params" port="result" />
  </p:output>
  <p:output port="report" primary="false">
    <p:inline>
      <c:reports>
        <c:report type="idml2xml:single-doc" step="Document">
          <c:success/>
        </c:report>
      </c:reports>
    </p:inline>
  </p:output>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
<!--  <p:import href="http://transpect.io/calabash-extensions/transpect-lib.xpl"/>-->
  <p:import href="http://transpect.io/calabash-extensions/unzip-extension/unzip-declaration.xpl"/>
  <!--  <p:import href="http://transpect.io/calabash-extensions/transpect-lib.xpl" />-->
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <tr:file-uri name="file-uri">
    <p:with-option name="filename" select="$idmlfile"/>
  </tr:file-uri>

  <!--<cx:message>
    <p:with-option name="message" select="string-join(for $a in /*/@* return concat(name($a), '=', $a), ', ')"></p:with-option>
  </cx:message>-->

  <tr:unzip name="unzip">
    <p:with-option name="zip" select="/*/@os-path" />
    <p:with-option name="dest-dir" select="concat(/*/@os-path, '.tmp')"/>
    <p:with-option name="overwrite" select="'yes'" />
  </tr:unzip>

  <p:choose>
    <p:when test="name(/*) eq 'c:error'">
      <cx:message>
        <p:with-option name="message" select="'idml2hub error on unzipping.&#xa;', //text(), '&#xa;'"/>
      </cx:message>
    </p:when>
    <p:otherwise>
      <p:identity/>
    </p:otherwise>
  </p:choose>

  <p:sink/>

  <p:xslt name="zip-manifest">
    <p:input port="source">
      <p:pipe port="result" step="unzip"/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0">
          <xsl:template match="c:files">
            <c:zip-manifest>
              <xsl:apply-templates/>
            </c:zip-manifest>
          </xsl:template>
          <xsl:variable name="base-uri" select="/*/@xml:base" as="xs:string"/>
          <xsl:template match="c:file">
            <c:entry name="{replace(replace(@name, '%5B', '['), '%5D', ']')}"
              href="{concat($base-uri, replace(replace(@name, '\[', '%5B'), '\]', '%5D'))}" compression-method="deflate"
              compression-level="default"/>
          </xsl:template>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
  </p:xslt>
  <p:sink/>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'src-dir-uri']" attribute-name="value">
    <p:input port="source">
      <p:inline>
        <c:param-set>
          <!-- Switch off XSLT-based debugging: -->
          <c:param name="debug" value="'0'" />
          <c:param name="src-dir-uri" />
          <c:param name="hub-version" />
          <c:param name="srcpaths" />
          <c:param name="all-styles" />
          <c:param name="discard-tagging" />
          <c:param name="process-embedded-images" />
          <c:param name="hub-other-elementnames-whitelist" />
          <c:param name="output-items-not-on-workspace" />
        </c:param-set>
      </p:inline>
    </p:input>
    <p:with-option name="attribute-value" select="escape-html-uri(/c:files/@xml:base)">
      <p:pipe step="unzip" port="result" />
    </p:with-option>
  </p:add-attribute>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'hub-version']" attribute-name="value">
    <p:with-option name="attribute-value" select="$hub-version"/>
  </p:add-attribute>
  
  <p:add-attribute match="/c:param-set/c:param[@name eq 'discard-tagging']" attribute-name="value">
    <p:with-option name="attribute-value" select="$discard-tagging"/>
  </p:add-attribute>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'all-styles']" attribute-name="value">
    <p:with-option name="attribute-value" select="$all-styles"/>
  </p:add-attribute>
  
  <p:add-attribute match="/c:param-set/c:param[@name eq 'srcpaths']" attribute-name="value">
    <p:with-option name="attribute-value" select="$srcpaths"/>
  </p:add-attribute>
  
  <p:add-attribute match="/c:param-set/c:param[@name eq 'process-embedded-images']" attribute-name="value">
    <p:with-option name="attribute-value" select="$process-embedded-images"/>
  </p:add-attribute>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'hub-other-elementnames-whitelist']" attribute-name="value">
    <p:with-option name="attribute-value" select="$hub-other-elementnames-whitelist"/>
  </p:add-attribute>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'output-items-not-on-workspace']" attribute-name="value" name="xslt-params">
    <p:with-option name="attribute-value" select="$output-items-not-on-workspace"/>
  </p:add-attribute>
  
  <tr:store-debug pipeline-step="idml2xml/idml2xml.04.Parameters">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="if (not($debug-dir-uri) or $debug-dir-uri  = '')
      then concat(/c:param-set/c:param[@name eq 'src-dir-uri'], 'debug') 
      else $debug-dir-uri">
      <p:pipe step="xslt-params" port="result"/>
    </p:with-option>
  </tr:store-debug>
    
  <p:sink/>
  
  <p:load name="designmap">
    <p:with-option name="href" select="concat(/c:files/@xml:base, 'designmap.xml')">
      <p:pipe step="unzip" port="result"/>
    </p:with-option>
  </p:load>

  <p:xslt name="Document" initial-mode="idml2xml:Document">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="idml_single-doc" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="idml2xml/idml2xml.05.Document">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="if (not($debug-dir-uri) or $debug-dir-uri  = '')
                                           then concat(/c:param-set/c:param[@name eq 'src-dir-uri'], 'debug') 
                                           else $debug-dir-uri">
      <p:pipe step="xslt-params" port="result"/>
    </p:with-option>
  </tr:store-debug>
  
  <p:sink/>
  
</p:declare-step>
