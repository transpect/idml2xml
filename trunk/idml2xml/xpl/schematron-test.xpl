<?xml version="1.0" encoding="utf-8"?>
<p:pipeline xmlns:p="http://www.w3.org/ns/xproc" 
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

  <p:option name="idmlfile" />

  <p:output port="svrl" sequence="true">
    <p:pipe step="svrl-multiplex" port="result"/>
  </p:output>

  <p:import href="idml2xml.xpl" />

  <idml2xml:hub name="idml2xml">
    <p:with-option name="idmlfile" select="$idmlfile"/>
  </idml2xml:hub>

  <p:sink/>

  <p:identity name="sch-params">
    <p:input port="source">
      <p:inline>
        <c:param-set>
          <c:param name="allow-foreign" value="true" />
          <c:param name="select-contexts" value="//" />
          <c:param name="visit-text" value="neither-true-nor-false" />
        </c:param-set>
      </p:inline>
    </p:input>
  </p:identity>

  <p:sink/>

  <p:validate-with-schematron assert-valid="false" name="DocumentStoriesSorted">
    <p:input port="source">
      <p:pipe step="idml2xml" port="DocumentStoriesSorted" />
    </p:input>
    <p:input port="schema">
      <p:document href="../sch/DocumentStoriesSorted.sch.xml" />
    </p:input>
    <p:input port="parameters">
      <p:pipe step="sch-params" port="result" />
    </p:input>
  </p:validate-with-schematron>

  <p:sink/>

  <p:validate-with-schematron assert-valid="false" name="XML-Hubformat-cleanup-paras-and-br">
    <p:input port="source">
      <p:pipe step="idml2xml" port="XML-Hubformat-cleanup-paras-and-br" />
    </p:input>
    <p:input port="schema">
      <p:document href="../sch/XML-Hubformat-cleanup-paras-and-br.sch.xml" />
    </p:input>
    <p:input port="parameters">
      <p:pipe step="sch-params" port="result" />
    </p:input>
  </p:validate-with-schematron>

  <p:sink/>

  <p:identity name="svrl-multiplex">
    <p:input port="source">
      <p:pipe step="DocumentStoriesSorted" port="report" />
      <p:pipe step="XML-Hubformat-cleanup-paras-and-br" port="report" />
    </p:input>
  </p:identity>

  <p:identity>
    <p:input port="source">
      <p:inline>
        <ok/>
      </p:inline>
    </p:input>
  </p:identity>

</p:pipeline>
