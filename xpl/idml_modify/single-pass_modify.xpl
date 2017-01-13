<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="modify">
  
  <p:documentation>XPL file for a single conversion in mode idml2xml:modify.
    Normally, the source input is the compound-document (result of idml2xml:Document).
    If you only need to pass additional input documents, you can use this XProc file too (port: external-sources).
    Use collection[2], collection[3] (and so on) to access these documents.</p:documentation>

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="disable-images" required="false" select="'no'"/>
  
  <p:input port="source" primary="true" />
  <p:input port="stylesheet" />
  <p:input port="parameters" kind="parameter" primary="true"/>
  <p:output port="result" primary="true" />
  
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <p:split-sequence name="eventually-split" test="position() = 1" initial-only="true">
    <p:documentation>By default, split will return one document: the compound-document (at the port 'matched'). 
      Any additional sources given are put into the 'not-matched' bucket.</p:documentation>
  </p:split-sequence>

  <p:choose name="params">
    <p:when test="$disable-images = 'yes'">
      <p:output port="result">
        <p:pipe port="result" step="add-param"/>
      </p:output>
      <p:parameters name="consolidate-params">
        <p:input port="parameters">
          <p:pipe port="parameters" step="modify"/>
        </p:input>
      </p:parameters>
      <p:add-attribute match="/*" attribute-name="value" name="add-param">
       <p:with-option name="attribute-value" select="'yes'"/>
       <p:input port="source">
         <p:inline>
           <c:param name="disable-images"/>
         </p:inline>
       </p:input>
    </p:add-attribute>
    </p:when>
    <p:otherwise>
      <p:output port="result">
        <p:pipe port="result" step="param-identity"/>
      </p:output>
      <p:parameters name="param-identity">
        <p:input port="parameters">
          <p:pipe port="parameters" step="modify"/>
        </p:input>
      </p:parameters>
    </p:otherwise>
  </p:choose>
  
  <tr:xslt-mode msg="yes" mode="idml2xml:modify" prefix="idml_modify/modify">
    <p:input port="source">
      <p:pipe step="eventually-split" port="matched"/>
      <p:pipe step="eventually-split" port="not-matched"/>
    </p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="modify"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
  </tr:xslt-mode>
  
</p:declare-step>
