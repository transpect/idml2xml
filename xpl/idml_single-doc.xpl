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
  <p:option name="fixed-layout" required="false" select="'no'"/>
  <p:option name="numeric-font-weight-values" required="false" select="'no'"/>
  <p:option name="preserve-original-image-refs" required="false" select="'no'"/>
  <p:option name="hub-other-elementnames-whitelist" required="false" select="''"/>
  <p:option name="output-items-not-on-workspace" required="false" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="status-dir-uri" required="false" select="'debug/status'"/>
  <p:option name="item-not-on-workspace-pt-tolerance" required="false" select="'0'"/>
  <p:option name="fail-on-error" select="'no'"/>
  
  <p:input port="xslt-stylesheet">
    <p:document href="../xsl/idml2xml.xsl"/>
  </p:input>
  <p:output port="result" primary="true" >
    <p:pipe port="result" step="try"/>
  </p:output>
  <p:output port="zip-manifest">
    <p:pipe step="try" port="zip-manifest"/>
  </p:output>
  <p:output port="xslt-params">
    <p:pipe step="try" port="xslt-params"/>
  </p:output>
  <p:output port="report" sequence="true">
    <p:pipe port="report" step="try"/>
  </p:output>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
<!--  <p:import href="http://transpect.io/calabash-extensions/transpect-lib.xpl"/>-->
  <p:import href="http://transpect.io/calabash-extensions/unzip-extension/unzip-declaration.xpl"/>
  <!--  <p:import href="http://transpect.io/calabash-extensions/transpect-lib.xpl" />-->
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  
  <tr:file-uri name="file-uri">
    <p:with-option name="filename" select="$idmlfile"/>
  </tr:file-uri>

  <p:sink/>

  <p:try name="try">
    <p:group>
      <p:output port="result" primary="true" >
        <p:pipe step="Document" port="result"/>
      </p:output>
      <p:output port="zip-manifest">
        <p:pipe port="result" step="zip-manifest"/>
      </p:output>
      <p:output port="xslt-params">
        <p:pipe port="result" step="xslt-params"/>
      </p:output>
      <p:output port="report" sequence="true"/>
      
      <!--<cx:message>
        <p:with-option name="message" select="string-join(for $a in /*/@* return concat(name($a), '=', $a), ', ')"></p:with-option>
      </cx:message>-->

      <tr:unzip name="unzip">
        <p:with-option name="zip" select="/*/@os-path" >
          <p:pipe port="result" step="file-uri"/>
        </p:with-option>
        <p:with-option name="dest-dir" select="concat(/*/@os-path, '.tmp')">
          <p:pipe port="result" step="file-uri"/>
        </p:with-option>
        <p:with-option name="overwrite" select="'yes'" />
      </tr:unzip>
      <tr:store-debug pipeline-step="idml2xml/unzip">
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
    
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
      
      <tr:store-debug pipeline-step="idml2xml/zip-manifest">
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
      
      <p:sink/>
      
      <p:group name="xslt-params">
        <p:output port="result">
          <p:pipe port="result" step="create-param-set"/>
        </p:output>
        <p:variable name="src-dir-uri" select="escape-html-uri(/c:files/@xml:base)">
          <p:pipe step="unzip" port="result" />
        </p:variable>
        
        <p:in-scope-names name="create-param-set"/>
        
      </p:group>
      
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
    </p:group>

    <p:catch name="catch">
      <p:output port="result" primary="true" >
        <p:inline>
          <Document>An error occurred in idml_single-doc. Please see the error report.</Document>
        </p:inline>
      </p:output>
      <p:output port="zip-manifest">
        <p:inline>
          <c:zip-manifest/>
        </p:inline>
      </p:output>
      <p:output port="xslt-params">
        <p:inline>
          <c:param-set/>
        </p:inline>
      </p:output>
      <p:output port="report" sequence="true">
        <p:pipe port="result" step="forward-error"/>
      </p:output>
      
      <tr:propagate-caught-error name="forward-error" code="IDML_single-doc">
        <p:with-option name="fail-on-error" select="$fail-on-error"/>
        <p:input port="source">
          <p:pipe port="error" step="catch"/>
        </p:input>
        <p:with-option name="severity" select="'fatal-error'"/>
        <p:with-option name="msg-file" select="concat(/*/@lastpath, '.idml_single-doc.ERROR.txt')">
          <p:pipe port="result" step="file-uri"/>
        </p:with-option>
        <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
      </tr:propagate-caught-error>
      
      <p:sink/>
      
    </p:catch>
  </p:try>  

</p:declare-step>
