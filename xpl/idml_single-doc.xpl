<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  xmlns:letex="http://www.le-tex.de/namespace"
  version="1.0"
  name="idml_single-doc"
  type="idml2xml:single-doc"
  >

  <p:option name="idmlfile" />
  <p:option name="hub-version" required="false" select="'1.1'"/>
  <p:option name="srcpaths" required="false" select="'no'"/>
  <p:option name="discard-tagging" required="false" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:output port="result" primary="true" >
    <p:pipe step="Document" port="result"/>
  </p:output>
  <p:output port="xslt-params" primary="false">
    <p:pipe step="xslt-params" port="result" />
  </p:output>
  <p:output port="xslt-stylesheet" primary="false">
    <p:pipe step="load-stylesheet" port="result" />
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
  <p:import href="http://transpect.le-tex.de/calabash-extensions/ltx-unzip/ltx-lib.xpl" />
  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  
  <letex:unzip name="unzip">
    <p:with-option name="zip" select="$idmlfile" />
    <p:with-option name="dest-dir" select="concat($idmlfile, '.tmp')"/>
    <p:with-option name="overwrite" select="'yes'" />
  </letex:unzip>

  <p:sink/>

  <p:load name="load-stylesheet" href="../xslt/idml2xml.xsl" />

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
          <c:param name="discard-tagging" />
        </c:param-set>
      </p:inline>
    </p:input>
    <p:with-option name="attribute-value" select="/c:files/@xml:base">
      <p:pipe step="unzip" port="result" />
    </p:with-option>
  </p:add-attribute>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'hub-version']" attribute-name="value">
    <p:with-option name="attribute-value" select="$hub-version"/>
  </p:add-attribute>
  
  <p:add-attribute match="/c:param-set/c:param[@name eq 'discard-tagging']" attribute-name="value">
    <p:with-option name="attribute-value" select="$discard-tagging"/>
  </p:add-attribute>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'srcpaths']" attribute-name="value" name="xslt-params">
    <p:with-option name="attribute-value" select="$srcpaths"/>
  </p:add-attribute>
    
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
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <letex:store-debug pipeline-step="idml2xml/idml2xml.05.Document">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="if (not($debug-dir-uri) or $debug-dir-uri  = '')
                                           then concat(/c:parm-set/c:param[@name eq 'src-dir-uri'], 'debug') 
                                           else $debug-dir-uri">
      <p:pipe step="xslt-params" port="result"/>
    </p:with-option>
  </letex:store-debug>
  
  <p:sink/>
  
</p:declare-step>
