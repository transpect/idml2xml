<?xml version="1.0" encoding="utf-8"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" 
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

  <p:import href="idml2xml.xpl" />

  <p:declare-step type="idml2xml:patch-hub" name="patch-hub">

    <p:input port="source" primary="true" />
    <p:input port="svrl" sequence="true" />

    <p:output port="result" primary="true">
      <p:pipe step="patch" port="result"/>
    </p:output>

    <p:output port="xsl">
      <p:pipe step="create-patch-xsl" port="result"/>
    </p:output>

    <p:xslt name="create-patch-xsl">
      <p:input port="source">
  	    <p:pipe step="patch-hub" port="svrl"/>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="xsl/svrl2xsl.xsl"/>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>

    <p:sink/>

    <p:xslt name="patch">
      <p:input port="source">
        <p:pipe step="patch-hub" port="source" />
      </p:input>
      <p:input port="stylesheet">
        <p:pipe step="create-patch-xsl" port="result" />
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>

  </p:declare-step>


  <p:declare-step type="idml2xml:apply-schematron" name="apply-schematron">
    
    <p:input port="source" primary="true" />
    
    <p:input port="schema" />

    <p:output port="result" primary="true">
      <p:pipe step="test" port="report"/>
    </p:output>

    <p:validate-with-schematron assert-valid="false" name="test">
      <p:input port="source">
        <p:pipe step="apply-schematron" port="source" />
      </p:input>
      <p:input port="schema">
        <p:pipe step="apply-schematron" port="schema" />
      </p:input>
      <p:input port="parameters">
        <p:inline>
          <c:param-set>
            <c:param name="allow-foreign" value="true" />
            <c:param name="select-contexts" value="//" />
            <c:param name="visit-text" value="neither-true-nor-false" />
          </c:param-set>
        </p:inline>
      </p:input>
    </p:validate-with-schematron>

    <p:sink/>

  </p:declare-step>


  <p:declare-step type="idml2xml:apply-schematrons" name="apply-schematrons">

    <p:output port="report" sequence="true">
      <p:pipe step="tests" port="result"/>
    </p:output>

    <p:output port="result" primary="true">
      <p:pipe step="idml2xml" port="result"/>
    </p:output>

    <p:option name="conf-uri" />
    <p:option name="idmlfile-uri" />

    <p:load name="load-conf">
      <p:with-option name="href" select="$conf-uri"/>
    </p:load>

    <p:sink/>

    <idml2xml:hub name="idml2xml">
      <p:with-option name="idmlfile" select="$idmlfile-uri"/>
    </idml2xml:hub>

    <p:sink/>

    <p:group name="tests" xmlns:idml2xml="http://www.le-tex.de/namespace/idml2xml"
             xmlns:p="http://www.w3.org/ns/xproc">
      <p:output port="result" sequence="true">
        <p:pipe step="sample-schematron-reports" port="result"/>
      </p:output>
      <idml2xml:apply-schematron name="DocumentStoriesSorted">
          <p:input port="source">
             <p:pipe step="idml2xml" port="DocumentStoriesSorted"/>
          </p:input>
          <p:input port="schema">
             <p:document href="file:/C:/cygwin/home/gerrit/Dev/idml2xml/sch/DocumentStoriesSorted.sch.xml"/>
          </p:input>
       </idml2xml:apply-schematron>
      <idml2xml:apply-schematron name="XML-Hubformat-cleanup-paras-and-br">
          <p:input port="source">
             <p:pipe step="idml2xml" port="XML-Hubformat-cleanup-paras-and-br"/>
          </p:input>
          <p:input port="schema">
             <p:document href="file:/C:/cygwin/home/gerrit/Dev/idml2xml/sch/XML-Hubformat-cleanup-paras-and-br.sch.xml"/>
          </p:input>
       </idml2xml:apply-schematron>
       <p:identity name="sample-schematron-reports">
          <p:input port="source">
             <p:pipe port="result" step="DocumentStoriesSorted"/>
             <p:pipe port="result" step="XML-Hubformat-cleanup-paras-and-br"/>
          </p:input>
       </p:identity>
    </p:group>

  </p:declare-step>


</p:library>
