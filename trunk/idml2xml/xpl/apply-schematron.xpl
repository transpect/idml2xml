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


</p:library>
