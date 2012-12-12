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
  name="single2tagged"
  type="idml2xml:single2tagged"
  >

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>  

  <p:input port="source" primary="true"/>
  <p:input port="xslt-stylesheet" />
  <p:input port="xslt-params" />
  
  <p:output port="result" primary="true">
    <p:pipe step="AutoCorrect-clean-up" port="result" />
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false"/>
  <p:output port="DocumentStoriesSorted">
    <p:pipe step="DocumentStoriesSorted" port="result" />
  </p:output>
  <p:serialization port="DocumentStoriesSorted" indent="true" omit-xml-declaration="false"/>
  <p:output port="GenerateTagging">
    <p:pipe step="GenerateTagging" port="result" />
  </p:output>
  <p:serialization port="GenerateTagging" indent="true" omit-xml-declaration="false"/>
  <p:output port="ExtractTagging">
    <p:pipe step="ExtractTagging" port="result" />
  </p:output>
  <p:serialization port="ExtractTagging" indent="true" omit-xml-declaration="false"/>
  <p:output port="AutoCorrect">
    <p:pipe step="AutoCorrect" port="result" />
  </p:output>
  <p:serialization port="AutoCorrect" indent="true" omit-xml-declaration="false"/>

  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  
  <p:xslt name="DocumentStoriesSorted" initial-mode="idml2xml:DocumentStoriesSorted">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <p:xslt name="SeparateParagraphs-pull-down-psrange" initial-mode="idml2xml:SeparateParagraphs-pull-down-psrange">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <p:xslt name="SeparateParagraphs" initial-mode="idml2xml:SeparateParagraphs">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <p:xslt name="ConsolidateParagraphStyleRanges-pull-up-Br" initial-mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <p:xslt name="ConsolidateParagraphStyleRanges-remove-empty" initial-mode="idml2xml:ConsolidateParagraphStyleRanges-remove-empty">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <p:xslt name="ConsolidateParagraphStyleRanges" initial-mode="idml2xml:ConsolidateParagraphStyleRanges">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <p:xslt name="GenerateTagging" initial-mode="idml2xml:GenerateTagging">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <letex:store-debug pipeline-step="idml2xml/idml2xml.29.GenerateTagging">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>
  
  <p:xslt name="ExtractTagging" initial-mode="idml2xml:ExtractTagging">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <letex:store-debug pipeline-step="idml2xml/idml2xml.30.ExtractTagging">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>
  
  <p:xslt name="AutoCorrect" initial-mode="idml2xml:AutoCorrect">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <letex:store-debug pipeline-step="idml2xml/idml2xml.50.AutoCorrect">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>

  <p:xslt name="AutoCorrect-clean-up" initial-mode="idml2xml:AutoCorrect-clean-up">
    <p:input port="parameters">
      <p:pipe step="single2tagged" port="xslt-params" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="single2tagged" port="xslt-stylesheet"/>
    </p:input>
  </p:xslt>

  <letex:store-debug pipeline-step="idml2xml/idml2xml.52.AutoCorrect-clean-up">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </letex:store-debug>
  
  <p:sink/>

</p:declare-step>
