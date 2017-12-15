<?xml version="1.0" encoding="utf-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tr="http://transpect.io" 
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:aid="http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5="http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml="http://transpect.io/idml2xml"
  version="1.0"
  name="idml_single-doc-sorted"
  type="idml2xml:single-doc-sorted"
  >

  <p:documentation>
    The purpose of this XProc pipeline is to produce a single xml document
    with sorted text frames for schematron checks.
  </p:documentation>

  <p:option name="idmlfile" required="true"/>
  <p:option name="srcpaths" required="false" select="'yes'"/>
  <p:option name="discard-tagging" required="false" select="'no'"/>
  <p:option name="output-items-not-on-workspace" required="false" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="status-dir-uri" required="false" select="'debug/status'"/>
  <p:option name="fail-on-error" select="'no'"/>
  
  <p:input port="xslt-stylesheet">
    <p:document href="../xsl/idml2xml.xsl"/>
  </p:input>
  <p:input port="xslt-stylesheet-docsorted2html">
    <p:document href="../xsl/idml_doc-sorted/docsorted2html.xsl"/>
  </p:input>
  <p:output port="result" primary="true">
    <p:pipe port="result" step="DocumentStoriesSorted"/>
  </p:output>
  <p:output port="result-html">
    <p:pipe port="result" step="try-html"/>
  </p:output>
  <p:output port="zip-manifest">
    <p:pipe port="zip-manifest" step="single"/>
  </p:output>
  <p:output port="xslt-params">
    <p:pipe port="xslt-params" step="single"/>
  </p:output>
  <p:output port="report" sequence="true">
    <p:pipe port="report" step="single"/>
  </p:output>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="idml_single-doc.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <tr:simple-progress-msg name="start-msg" file="idml_single-doc-sorted-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting IDML to single/sorted XML conversion</c:message>
          <c:message xml:lang="de">Beginne Konvertierung von IDML zu sortierter XML</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

  <idml2xml:single-doc name="single">
    <p:input port="xslt-stylesheet">
      <p:pipe port="xslt-stylesheet" step="idml_single-doc-sorted"/>
    </p:input>
    <p:with-option name="idmlfile" select="$idmlfile"/>  
    <p:with-option name="debug" select="$debug"/>  
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="srcpaths" select="$srcpaths"/>
    <p:with-option name="discard-tagging" select="$discard-tagging"/>
    <p:with-option name="output-items-not-on-workspace" select="$output-items-not-on-workspace"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </idml2xml:single-doc>

  <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.20" mode="idml2xml:DocumentStoriesSorted" name="DocumentStoriesSorted">
    <p:input port="parameters"><p:pipe step="single" port="xslt-params"/></p:input>
    <p:input port="stylesheet"><p:pipe step="idml_single-doc-sorted" port="xslt-stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
  </tr:xslt-mode>

  <p:try name="try-html">
    <p:group>
      <p:output port="result" primary="true"/>

      <tr:xslt-mode msg="yes" prefix="idml2xml/idml2xml.20h" mode="idml2xml:docsorted2html" name="DocSorted2HTML">
        <p:input port="parameters"><p:pipe step="single" port="xslt-params"/></p:input>
        <p:input port="stylesheet"><p:pipe step="idml_single-doc-sorted" port="xslt-stylesheet-docsorted2html"/></p:input>
        <p:input port="models"><p:empty/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        <p:with-option name="fail-on-error" select="$fail-on-error"/>
      </tr:xslt-mode>

      <tr:store-debug pipeline-step="idml2xml/idml2xml.DocSorted2HTML">
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="if (not($debug-dir-uri) or $debug-dir-uri  = '')
                                               then concat(/c:param-set/c:param[@name eq 'src-dir-uri'], 'debug') 
                                               else $debug-dir-uri">
          <p:pipe step="single" port="xslt-params"/>
        </p:with-option>
      </tr:store-debug>
      
    </p:group>

    <p:catch name="catch">
      <p:output port="result" primary="true">
        <p:inline>
          <html xmlns="http://www.w3.org/1999/xhtml">
            <body xmlns="http://www.w3.org/1999/xhtml">An error occurred in idml_single-doc-sorted. Please see the error report.</body>
          </html>
        </p:inline>
      </p:output>

      <p:sink/>
      
    </p:catch>
  </p:try>  

  <tr:simple-progress-msg name="success-msg" file="idml_single-doc-sorted-success.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Successfully finished IDML to single/sorted XML conversion</c:message>
          <c:message xml:lang="de">Konvertierung von IDML zu sortierter XML erfolgreich abgeschlossen</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

  <p:sink/>
  
</p:declare-step>
