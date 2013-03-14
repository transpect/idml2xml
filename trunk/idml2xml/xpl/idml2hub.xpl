<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  version="1.0"
  name="idml2xml"
  type="idml2xml:hub"
  >

  <p:option name="idmlfile" />
  <p:option name="hub-version" required="false" select="'1.1'"/>
  <p:option name="srcpaths" required="false" select="'no'"/>
  <p:option name="all-styles" required="false" select="'no'"/>
  <p:option name="discard-tagging" required="false" select="'yes'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  
  <p:output port="Document">
    <p:pipe step="single" port="result" />
  </p:output>
  <p:serialization port="Document" omit-xml-declaration="false"/>
  <p:output port="DocumentStoriesSorted">
    <p:pipe step="tagged" port="DocumentStoriesSorted" />
  </p:output>
  <p:serialization port="DocumentStoriesSorted" omit-xml-declaration="false"/>
  <p:output port="tagged">
    <p:pipe step="tagged" port="result" />
  </p:output>
  <p:serialization port="tagged" omit-xml-declaration="false"/>
  <p:output port="result" primary="true" sequence="true">
    <p:pipe step="pi" port="result" />
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false" />

  <p:import href="idml_single-doc.xpl"/>
  <p:import href="idml_single2tagged.xpl"/>
  <p:import href="idml_tagged2hub.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/xml-model/prepend-hub-xml-model.xpl" />
  

  <idml2xml:single-doc name="single">
    <p:with-option name="idmlfile" select="$idmlfile"/>  
    <p:with-option name="debug" select="$debug"/>  
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="srcpaths" select="$srcpaths"/>  
    <p:with-option name="all-styles" select="$all-styles"/>  
    <p:with-option name="discard-tagging" select="$discard-tagging"/>
    <p:with-option name="hub-version" select="$hub-version"/>  
  </idml2xml:single-doc>
  
  <idml2xml:single2tagged name="tagged">
    <p:with-option name="debug" select="$debug"/>  
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="xslt-stylesheet">
      <p:pipe port="xslt-stylesheet" step="single"></p:pipe>
    </p:input>
    <p:input port="xslt-params">
      <p:pipe port="xslt-params" step="single"></p:pipe>
    </p:input>
  </idml2xml:single2tagged>

  <idml2xml:tagged2hub name="hub">
    <p:with-option name="debug" select="$debug"/>  
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="hub-version" select="$hub-version"/>  
    <p:input port="xslt-stylesheet">
      <p:pipe port="xslt-stylesheet" step="single"></p:pipe>
    </p:input>
    <p:input port="xslt-params">
      <p:pipe port="xslt-params" step="single"></p:pipe>
    </p:input>
  </idml2xml:tagged2hub>

  <letex:prepend-hub-xml-model name="pi">
    <p:with-option name="hub-version" select="$hub-version"/>
  </letex:prepend-hub-xml-model>

</p:declare-step>
