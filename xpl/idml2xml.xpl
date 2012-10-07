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
  name="idml2xml"
  type="idml2xml:hub"
  >

  <p:option name="idmlfile" />


  <p:output port="result" primary="true">
    <p:pipe step="XML-Hubformat-cleanup-paras-and-br" port="result" />
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
  <p:output port="XML-Hubformat-cleanup-paras-and-br">
    <p:pipe step="XML-Hubformat-cleanup-paras-and-br" port="result" />
  </p:output>
  <p:serialization port="XML-Hubformat-cleanup-paras-and-br" indent="true" omit-xml-declaration="false"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.le-tex.de/calabash-extensions/ltx-unzip/ltx-lib.xpl" />

  <letex:unzip name="unzip">
    <p:with-option name="zip" select="$idmlfile" />
    <p:with-option name="dest-dir" select="concat($idmlfile, '.tmp')">
      <p:pipe step="idml2xml" port="source"/>
    </p:with-option>
    <p:with-option name="overwrite" select="'yes'" />
  </letex:unzip>

  <p:sink/>

  <p:load name="load-stylesheet" href="../xslt/idml2xml.xsl" />

  <p:sink/>

  <p:add-attribute match="/c:param-set/c:param[@name eq 'src-dir-uri']" attribute-name="value" name="xslt-params">
    <p:input port="source">
      <p:inline>
        <c:param-set>
          <c:param name="debug" value="'0'" />
          <c:param name="src-dir-uri" />
        </c:param-set>
      </p:inline>
    </p:input>
    <p:with-option name="attribute-value" select="/c:files/@xml:base">
      <p:pipe step="unzip" port="result" />
    </p:with-option>
  </p:add-attribute>


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

  <p:xslt name="DocumentStoriesSorted" initial-mode="idml2xml:DocumentStoriesSorted">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="SeparateParagraphs-pull-down-psrange" initial-mode="idml2xml:SeparateParagraphs-pull-down-psrange">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="SeparateParagraphs" initial-mode="idml2xml:SeparateParagraphs">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="ConsolidateParagraphStyleRanges-pull-up-Br" initial-mode="idml2xml:ConsolidateParagraphStyleRanges-pull-up-Br">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="ConsolidateParagraphStyleRanges-remove-empty" initial-mode="idml2xml:ConsolidateParagraphStyleRanges-remove-empty">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="ConsolidateParagraphStyleRanges" initial-mode="idml2xml:ConsolidateParagraphStyleRanges">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="GenerateTagging" initial-mode="idml2xml:GenerateTagging">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="ExtractTagging" initial-mode="idml2xml:ExtractTagging">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="AutoCorrect" initial-mode="idml2xml:AutoCorrect">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="AutoCorrect-clean-up" initial-mode="idml2xml:AutoCorrect-clean-up">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="XML-Hubformat-add-properties" initial-mode="idml2xml:XML-Hubformat-add-properties">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="XML-Hubformat-properties2atts" initial-mode="idml2xml:XML-Hubformat-properties2atts">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="XML-Hubformat-extract-frames" initial-mode="idml2xml:XML-Hubformat-extract-frames">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="XML-Hubformat-remap-para-and-span" initial-mode="idml2xml:XML-Hubformat-remap-para-and-span">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:xslt name="XML-Hubformat-cleanup-paras-and-br" initial-mode="idml2xml:XML-Hubformat-cleanup-paras-and-br">
    <p:input port="parameters">
      <p:pipe step="xslt-params" port="result" />
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-stylesheet" port="result"/>
    </p:input>
  </p:xslt>

  <p:sink/>

</p:declare-step>
