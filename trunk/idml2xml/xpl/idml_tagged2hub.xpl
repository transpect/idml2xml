<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  xmlns:letex="http://www.le-tex.de/namespace"
  version="1.0"
  name="tagged2hub"
  type="idml2xml:tagged2hub"
  >

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>  
  <p:option name="hub-version" required="false" select="'1.2'"/>  
  <p:option name="process-embedded-images" required="false" select="'yes'"/>
  
  <p:input port="source" primary="true"/>
  <p:input port="xslt-stylesheet" />
  <p:input port="xslt-params" />
  
  <p:output port="result" primary="true">
    <p:pipe step="XML-Hubformat-cleanup-paras-and-br" port="result" />
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/xslt-mode/xslt-mode.xpl"/>
  
  <letex:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.07" mode="idml2xml:XML-Hubformat-add-properties">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </letex:xslt-mode>
  
  <letex:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.07a" mode="idml2xml:XML-Hubformat-properties2atts">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </letex:xslt-mode>
  
  <letex:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.08" mode="idml2xml:XML-Hubformat-extract-frames">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </letex:xslt-mode>
  
  <letex:xslt-mode name="remap-para-and-span"
    msg="yes" prefix="idml2xml/idml2xml.HUB.10" mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </letex:xslt-mode>

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
  
  <letex:xslt-mode msg="yes" prefix="idml2xml/idml2xml.HUB.15" mode="idml2xml:XML-Hubformat-cleanup-paras-and-br" name="XML-Hubformat-cleanup-paras-and-br">
    <p:input port="source"><p:pipe step="remap-para-and-span" port="result" /></p:input>
    <p:input port="parameters"><p:pipe step="tagged2hub" port="xslt-params" /></p:input>
    <p:input port="stylesheet"><p:pipe step="tagged2hub" port="xslt-stylesheet" /></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="hub-version" select="$hub-version"/>
  </letex:xslt-mode>
  
  <p:sink/>

</p:declare-step>
