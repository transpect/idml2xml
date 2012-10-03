<?xml version="1.0" encoding="utf-8"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"  
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml = "http://www.w3.org/1999/xhtml"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://www.le-tex.de/namespace/idml2xml"
  xmlns:ltx="http://le-tex.de/tools/unzip"
  version="1.0"
  >

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />

  <p:declare-step type="idml2xml:patch-hub" name="patch-hub">

    <p:input port="source" primary="true" />
    <p:input port="svrl"  />

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


  <p:declare-step type="idml2xml:apply-schematrons" name="apply-schematrons">

    <p:output port="result" primary="true">
      <p:pipe step="result" port="result"/>
     </p:output>

    <p:output port="report">
      <p:pipe step="report" port="result"/>
     </p:output>

    <p:output port="xpl">
      <p:pipe step="generate-schematron-pipeline" port="result"/>
    </p:output>

    <p:option name="conf-uri" />
    <p:option name="idmlfile-uri" />

    <p:load name="load-conf">
      <p:with-option name="href" select="$conf-uri"/>
    </p:load>

    <p:xslt name="generate-schematron-pipeline">
      <p:input port="stylesheet">
        <p:document href="xsl/conf2xpl.xsl" />
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>

    <p:sink/>

    <p:add-attribute match="/cx:options/cx:option" attribute-name="value" name="pipeline-options">
      <p:input port="source">
        <p:inline>
          <cx:options>
            <cx:option name="idmlfile"/>
          </cx:options>
        </p:inline>
      </p:input>
      <p:with-option name="attribute-value" select="$idmlfile-uri" />
    </p:add-attribute>
  
    <p:sink/>

    <cx:eval name="schematron-pipeline">
      <p:input port="source"><p:empty/></p:input>
      <p:input port="pipeline">
        <p:pipe step="generate-schematron-pipeline" port="result"/>
      </p:input>
      <p:input port="options">
        <p:pipe step="pipeline-options" port="result" />
      </p:input>
    </cx:eval>

    <p:identity name="report">
      <p:input port="source" select="/cx:documents/c:reports" />
    </p:identity>

    <p:sink/>

    <p:identity name="result">
      <p:input port="source" select="/cx:documents/c:result/*">
        <p:pipe step="schematron-pipeline" port="result"/>
      </p:input>
    </p:identity>

    <p:sink/>

    <!--



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
       <p:wrap-sequence name="sample-schematron-reports" wrapper="c:reports">
          <p:input port="source">
             <p:pipe port="result" step="DocumentStoriesSorted"/>
             <p:pipe port="result" step="XML-Hubformat-cleanup-paras-and-br"/>
          </p:input>
       </p:wrap-sequence>
    </p:group>


-->

  </p:declare-step>


</p:library>
