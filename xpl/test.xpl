<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  xmlns:ltx="http://le-tex.de/tools/unzip"
  version="1.0"
  >

  <p:serialization port="svrl" indent="true" omit-xml-declaration="false"/>
  <p:serialization port="result" indent="true" omit-xml-declaration="false"/>
  <p:serialization port="xsl" indent="true" omit-xml-declaration="false"/>


  <p:option name="idmlfile" />
  <p:option name="conffile" />

  <p:output port="svrl" sequence="true">
    <p:pipe step="test" port="report"/>
  </p:output>

  <p:output port="result" primary="true">
    <p:pipe step="patch" port="result"/>
  </p:output>

  <p:output port="xsl">
    <p:pipe step="patch" port="xsl"/>
  </p:output>

  <p:import href="schematron.xpl" />

  <idml2xml:apply-schematrons name="test">
    <p:with-option name="idmlfile-uri" select="$idmlfile"/>
    <p:with-option name="conf-uri" select="$conffile"/>
  </idml2xml:apply-schematrons>

  <idml2xml:patch-hub name="patch">
    <p:input port="svrl">
      <p:pipe step="test" port="report"/>
    </p:input>
  </idml2xml:patch-hub>

  <p:sink/>


</p:declare-step>
