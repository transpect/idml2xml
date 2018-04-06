<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  xmlns:tr    = "http://transpect.io" 
  version="1.0"
  name="tagged2hub"
  type="idml2xml:tagged2hub"
  >

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  <p:option name="fail-on-error" required="false" select="'yes'"/>
  <p:option name="hub-version" required="false" select="'1.2'"/>  
  <p:option name="process-embedded-images" required="false" select="'yes'"/>
  <p:option name="mathtype2mml" required="false" select="'yes'"/>
  <p:option name="mathtype-source-pi" required="false" select="'no'"/>
  
  <p:input port="source" primary="true"/>
  <p:input port="xslt-stylesheet" />
  <p:input port="xslt-params" />
  <p:input port="custom-font-maps" primary="false" sequence="true">
    <p:documentation>
      See additional-font-maps in mathtype-extension
    </p:documentation>
    <p:empty/>
  </p:input>
  
  <p:output port="report" sequence="true">
    <p:pipe port="report" step="add-properties"/>
    <p:pipe port="report" step="properties2atts"/>
    <p:pipe port="report" step="extract-frames"/>
    <p:pipe port="report" step="remap-para-and-span"/>
    <p:pipe port="report" step="cleanup-paras-and-br"/>
  </p:output>
  <p:output port="result" primary="true">
    <p:pipe step="cleanup-paras-and-br" port="result" />
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.07" mode="idml2xml:XML-Hubformat-add-properties" name="add-properties">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.07a" mode="idml2xml:XML-Hubformat-properties2atts" name="properties2atts">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.08" mode="idml2xml:XML-Hubformat-extract-frames" name="extract-frames">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode name="remap-para-and-span"
    msg="yes" prefix="idml2xml/idml2xml.HUB.10" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </tr:xslt-mode>
  
  <p:sink/>
  <!--  *
        * iterate over embedded base64 binary blobs
        * -->
  <p:for-each name="rewrite-base64-result-documents-to-base64">
    <p:iteration-source select="/*[@encoding eq 'base64' and $process-embedded-images eq 'yes']">
      <p:pipe step="remap-para-and-span" port="secondary"/>
    </p:iteration-source>
    
    <p:rename name="rename_idml2xml-data_to_c-data"
      match="/*" new-name="data" new-namespace="http://www.w3.org/ns/xproc-step" new-prefix="c"/>
    
    <p:store cx:decode="true" name="store-decoded-b64">
      <p:documentation>Notice: this cx:decode only works with c:data[@encoding eq 'base64']</p:documentation>
      <p:with-option name="href" select="base-uri(/*)"/>
    </p:store>
    
  </p:for-each>
  
  <idml2xml:mathtype2mml name="mathtype2mml">
    <p:input port="source">
      <p:pipe port="result" step="remap-para-and-span"/>
    </p:input>
    <p:input port="params">
      <p:pipe step="tagged2hub" port="xslt-params" />
    </p:input>
    <p:input port="custom-font-maps">
      <p:pipe port="custom-font-maps" step="tagged2hub"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="active" select="$mathtype2mml"/>
    <p:with-option name="sources" select="$mathtype2mml"/>
    <p:with-option name="source-pi" select="$mathtype-source-pi"/>
  </idml2xml:mathtype2mml>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.15" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" name="cleanup-paras-and-br">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </tr:xslt-mode>
  
  <p:sink/>

</p:declare-step>
