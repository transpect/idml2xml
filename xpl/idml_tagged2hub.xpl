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
  name="tagged2hub"
  type="idml2xml:tagged2hub"
  >

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>  
  <p:option name="hub-version" required="false" select="'1.1'"/>  
  
  <p:input port="source" primary="true"/>
  <p:input port="xslt-stylesheet" />
  <p:input port="xslt-params" />
  
  <p:output port="result" primary="true">
    <p:pipe step="XML-Hubformat-cleanup-paras-and-br" port="result" />
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false"/>
  <p:output port="add-properties">
    <p:pipe step="XML-Hubformat-add-properties" port="result" />
  </p:output>
  <p:serialization port="add-properties" indent="true" omit-xml-declaration="false"/>

  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  <p:import href="idml_lib.xpl"/>
  
  <p:xslt name="XML-Hubformat-add-properties" initial-mode="idml2xml:XML-Hubformat-add-properties">
    <p:input port="parameters">
      <p:pipe step="tagged2hub" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="tagged2hub" port="xslt-stylesheet" />
    </p:input>
  </p:xslt>
  
  <letex:store-debug pipeline-step="idml2xml/idml2xml.HUB.07.XML-Hubformat-add-properties">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>
  
  <p:xslt name="XML-Hubformat-properties2atts" initial-mode="idml2xml:XML-Hubformat-properties2atts">
    <p:input port="parameters">
      <p:pipe step="tagged2hub" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="tagged2hub" port="xslt-stylesheet" />
    </p:input>
  </p:xslt>
  
  <letex:store-debug pipeline-step="idml2xml/idml2xml.HUB.07a.XML-Hubformat-properties2atts">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>
  
  <p:xslt name="XML-Hubformat-extract-frames" initial-mode="idml2xml:XML-Hubformat-extract-frames">
    <p:input port="parameters">
      <p:pipe step="tagged2hub" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="tagged2hub" port="xslt-stylesheet" />
    </p:input>
  </p:xslt>
  
  <p:xslt name="XML-Hubformat-remap-para-and-span" initial-mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <p:input port="parameters">
      <p:pipe step="tagged2hub" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="tagged2hub" port="xslt-stylesheet" />
    </p:input>
  </p:xslt>
  
  <idml2xml:prepend-hub-xml-model>
    <p:with-option name="hub-version" select="$hub-version"/>
  </idml2xml:prepend-hub-xml-model>

  <letex:store-debug pipeline-step="idml2xml/idml2xml.HUB.10.XML-Hubformat-remap-para-and-span">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>
  
  <p:xslt name="XML-Hubformat-cleanup-paras-and-br" initial-mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <p:input port="parameters">
      <p:pipe step="tagged2hub" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="tagged2hub" port="xslt-stylesheet" />
    </p:input>
  </p:xslt>
  
  <idml2xml:prepend-hub-xml-model>
    <p:with-option name="hub-version" select="$hub-version"/>
  </idml2xml:prepend-hub-xml-model>
  
  <letex:store-debug pipeline-step="idml2xml/idml2xml.HUB.15.XML-Hubformat-cleanup-paras-and-br">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>

  <p:sink/>

</p:declare-step>
