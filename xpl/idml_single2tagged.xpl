<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  xmlns:tr    = "http://transpect.io" 
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
    <p:pipe step="JoinSpans" port="result" />
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

  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.20" mode="idml2xml:DocumentStoriesSorted" name="DocumentStoriesSorted">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.22" mode="idml2xml:SeparateParagraphs-pull-down-psrange">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.24" mode="idml2xml:SeparateParagraphs">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.26" mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.27" mode="idml2xml:ConsolidateParagraphStyleRanges-remove-empty">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.28" mode="idml2xml:ConsolidateParagraphStyleRanges">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.29" mode="idml2xml:GenerateTagging" name="GenerateTagging">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.30" mode="idml2xml:ExtractTagging" name="ExtractTagging">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.50" mode="idml2xml:AutoCorrect" name="AutoCorrect">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.52" mode="idml2xml:AutoCorrect-clean-up">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <p:choose>
    <p:when test="exists(//AllNestedStyles/ListItem)">
      <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.54" mode="idml2xml:NestedStyles-create-separators">
        <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
        <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
        <p:input port="models"><p:empty/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </tr:xslt-mode>
      
      <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.55" mode="idml2xml:NestedStyles-pull-up-separators">
        <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
        <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
        <p:input port="models"><p:empty/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </tr:xslt-mode>
      
      <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.56" mode="idml2xml:NestedStyles-apply">
        <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
        <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
        <p:input port="models"><p:empty/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </tr:xslt-mode>
    </p:when>
    <p:otherwise>
      <p:identity/>
    </p:otherwise>
  </p:choose>
  
  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.60" mode="idml2xml:JoinSpans" name="JoinSpans">
    <p:input port="parameters"><p:pipe step="single2tagged" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="single2tagged" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <p:sink/>

</p:declare-step>
