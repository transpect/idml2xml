<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  version="1.0"
  name="idml_modify"
  type="idml2xml:modify"
  >
  
  <p:option name="idmlfile" required="true">
    <p:documentation>As required by idml2hub</p:documentation>
  </p:option>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  <p:option name="idml-target-uri" required="false" select="''">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>URI where the generated idml will be saved. Possibilities:</p>
      <ul>
        <li>leave it empty to save the idml near the original idml file (only file suffix is changed to .mod.idml)</li>
        <li>absolute path to a file</li>
      </ul>
    </p:documentation>
  </p:option>
  <p:option name="srcpaths" required="false" select="'no'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Whether idml2xml adds srcpath attributes in mode insert-xpath to content elements or not. Example use: you have to 
        replace already modified content of the idml (external conversion) and match old nodes via @srcpath value.</p>
      <p>Default: no (saves time and memory)</p>
    </p:documentation>
  </p:option>
  <p:option name="hub-version" required="false" select="'1.2'"/>
  <!-- options of idml2hub -->
  <p:option name="status-dir-uri" required="false" select="'status'"/>
  <p:option name="disable-images" required="false" select="'no'"/>
  
 <p:input port="xslt">
    <p:document href="../../xsl/idml_modify/identity.xsl"/>
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>XSLT that transforms the compound IDML document (all files assembled below a single Document element,
      as produced by the step named idml2xml:Document to a target compound document. The stylesheet may of course import
    other stylesheets or use multiple passes in different modes. In order to facilitate this common processing pattern,
    an XProc pipeline may also be supplied for the compound→compound transformation part. This pipeline will be dynamically
    executed by this pipeline. Please note that your stylesheet must use named modes if you are using an tr:xslt-mode 
    pipeline.</p>
      <p>Please also note that if your pipeline/stylesheet don't have a pass in idml2xml:modify mode, they need 
    to match @xml:base in any of the other modifying modes and apply-templates to it in mode docxhub:modify.</p>
      <p>Please note that your stylesheet may need to import the identity.xsl or to transform the xml-base attributes itself 
    (old base→new base).</p>
      <p>Please also note that if your pipeline/stylesheet don't have a pass in idml2xml:modify mode, they need 
    to match @xml:base in any of the other modifying modes and apply-templates to it in mode docxhub:modify.</p>
    </p:documentation>
  </p:input>
  <p:input port="xpl">
    <p:document href="single-pass_modify.xpl"/>
    <p:documentation>See the 'xslt' port’s documentation. You may supply another pipeline that will be executed instead of 
      the default single-pass modify pipeline. You pipeline typically consists of chained transformations in different modes, 
      as invoked by tr:xslt-mode. Of course you can supply other pipelines with the same signature (single 
      idml2xml:Document input/output documents).</p:documentation>
  </p:input>
  <p:input port="params" kind="parameter" primary="true">
    <p:documentation>Arbitrary parameters that will be passed to the dynamically executed pipeline.</p:documentation>
  </p:input>
  <p:input port="external-sources" sequence="true">
    <p:documentation>Arbitrary source XML. Example: Hub XML that is transformed to IDML and then patched into the
    expanded docx template.</p:documentation>
  </p:input>
  <p:input port="options">
    <p:documentation>Options to the modifying XProc pipeline.</p:documentation>
  </p:input>
  
  <p:output port="result" primary="true">
    <p:documentation>A c:result element with an export-uri attribute of the modified idml file.</p:documentation>
    <p:pipe port="result" step="file-uri"/>
  </p:output>
  <p:output port="modified-idml">
    <p:documentation>An idml2xml:Document document. This output is mostly for Schematron checks. If you want Schematron
    with srcpaths</p:documentation>
    <p:pipe port="modified-idml" step="group"/>
  </p:output>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl" />
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl" />
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />
  <p:import href="http://transpect.io/xproc-util/zip/xpl/zip.xpl" />
  <p:import href="http://transpect.io/calabash-extensions/unzip-extension/unzip-declaration.xpl"/>
  
   <tr:file-uri name="file-uri">
    <p:with-option name="filename" select="$idmlfile"/>
  </tr:file-uri>
  
  <tr:store-debug>
    <p:with-option name="pipeline-step" select="'idml_modify/01.fileuri'"/>
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:group cx:depends-on="file-uri" name="group">
    <p:output port="result" primary="true" sequence="true">
      <p:pipe port="result" step="zip"/>
    </p:output>
    <p:output port="modified-idml">
      <p:pipe port="result" step="modify"/>
    </p:output>
    <p:variable name="basename" select="replace(/*/@lastpath, '\.idml$', '')"/>
    <p:variable name="os-path" select="/*/@os-path"/>
    <p:variable name="file-uri" select="/*/@local-href"/>
    <p:variable name="target-uri" select="if (matches($idml-target-uri, '^.+\.\w+$')) then $idml-target-uri else replace($file-uri, '\.idml$', '.mod.idml')">
      <p:pipe port="result" step="file-uri"/>
    </p:variable>
    
   <cx:message>
    <p:with-option name="message" select="'#### idml_modify: unzipping IDML file: ', $os-path, ' to ', concat($os-path, '.tmp'), ' disable images: ', $disable-images">
      <p:pipe port="result" step="file-uri"/>
    </p:with-option>
   </cx:message>
    
    <p:parameters name="consolidate-params">
      <p:input port="parameters">
        <p:pipe port="params" step="idml_modify"/>
      </p:input>
    </p:parameters>
    
   <tr:unzip name="unzip-first">
      <p:documentation>Unzip the IDML template to a temporary directory.</p:documentation>
      <p:with-option name="zip" select="$os-path" />
      <p:with-option name="dest-dir" select="concat($os-path, '.tmp')"/>
      <p:with-option name="overwrite" select="'yes'" />
    </tr:unzip>
    
     <p:xslt name="unzip-idml">
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
            <xsl:template match="* |@*">
              <xsl:copy>
                <xsl:apply-templates select="@*, node()"/>
              </xsl:copy>
            </xsl:template>
            <xsl:template match="@name">
              <xsl:attribute name="name" select="replace(replace(., '\[', '%5B'), '\]', '%5D')"/>
            </xsl:template>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>
    
     <tr:store-debug>
      <p:with-option name="pipeline-step" select="'idml_modify/02.file-list'"/>
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
     </tr:store-debug>
    
    <p:for-each name="copy">
      <p:iteration-source select="/c:files/c:file"/>
      <p:variable name="base-dir" select="replace(/c:files/@xml:base, '([^/])$', '$1/')">
        <p:pipe port="result" step="unzip-idml"/>
      </p:variable>
      <p:variable name="new-dir" select="replace($base-dir, '(\.idml)\.tmp/$', '$1.out/')"/>
      <p:variable name="name" select="/*/@name">
        <p:pipe port="current" step="copy"/>
      </p:variable>
      <cxf:mkdir>
        <p:with-option name="href" select="concat($new-dir, string-join(tokenize($name, '/')[position() lt last()], '/'))"/>
      </cxf:mkdir>
      <cxf:copy>
        <p:with-option name="href" select="concat($base-dir, $name)"/>
        <p:with-option name="target" select="concat($new-dir, $name)"/>
      </cxf:copy>
    </p:for-each>
    
    <p:load name="template-designmap">
     <p:documentation>Load the designmap.xml: the key in each IDML file 
       to all it´s included files.</p:documentation>
     <p:with-option name="href" select="concat(/c:files/@xml:base, '/designmap.xml')">
       <p:pipe step="unzip-idml" port="result"/>
     </p:with-option>
    </p:load>
    
    <p:xslt name="single-doc" initial-mode="idml2xml:Document">
      <p:documentation>Use first step of idml2xml to get a single XML instance 
        of the entire template file.</p:documentation>
      <p:with-param name="src-dir-uri" select="/c:files/@xml:base">
        <p:pipe step="unzip-idml" port="result" />
      </p:with-param>
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="stylesheet">
        <p:document href="http://transpect.io/idml2xml/xsl/idml2xml.xsl" />
      </p:input>
    </p:xslt>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="'idml_modify/03.Document'"/>
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
    </tr:store-debug>
    
     <p:wrap wrapper="cx:document" match="/">
      <p:input port="source">
        <p:pipe step="single-doc" port="result"/>
      </p:input>
    </p:wrap>
    <p:add-attribute name="idml-source" attribute-name="port" attribute-value="source" match="/*"/>
    
    <p:sink/>
    
    <p:for-each name="wrap-external-sources">
      <p:iteration-source>
        <p:pipe step="idml_modify" port="external-sources"/>
      </p:iteration-source>
      <p:output port="result" primary="true"/>
      <p:wrap wrapper="cx:document" match="/"/>
      <p:add-attribute attribute-name="port" attribute-value="source" match="/*"/>
    </p:for-each>
    
    <p:sink/>
    
    <p:wrap wrapper="cx:document" match="/">
      <p:input port="source">
        <p:pipe port="xslt" step="idml_modify"/>
      </p:input>
    </p:wrap>
    
    <p:add-attribute name="stylesheet" attribute-name="port" attribute-value="stylesheet" match="/*"/>
    
    <p:wrap wrapper="cx:document" match="/">
      <p:input port="source">
        <p:pipe step="consolidate-params" port="result"/>
      </p:input>
    </p:wrap>
    <p:add-attribute name="parameters" attribute-name="port" attribute-value="parameters" match="/*"/>
    
    <p:sink/>

    <p:xslt name="options" template-name="main">
      <p:documentation>Options for the dynamically executed pipeline. You may supply additional
      options using a cx:options document with cx:option name/value entries.</p:documentation>
      <p:with-param name="file" select="$file-uri"/>
      <p:with-param name="debug" select="$debug"/>
      <p:with-param name="debug-dir-uri" select="replace($debug-dir-uri, '^(.+)\?.*$', '$1')"/>
      <p:with-param name="disable-images" select="$disable-images"/>
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="source">
        <p:pipe step="idml_modify" port="options"/> 
      </p:input>
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
            <xsl:param name="file" as="xs:string"/>
            <xsl:param name="debug" as="xs:string"/>
            <xsl:param name="debug-dir-uri" as="xs:string"/>
            <xsl:param name="disable-images" as="xs:string"/>
            <xsl:template name="main">
              <cx:options>
                <cx:option name="debug" value="{$debug}"/>
                <cx:option name="debug-dir-uri" value="{replace($debug-dir-uri, '^(.+)\?.*$', '$1')}"/>
                <cx:option name="file" value="{$file}"/>
                <cx:option name="disable-images" value="{$disable-images}"/>
                <xsl:sequence select="collection()/cx:options/cx:option"/>
              </cx:options>
            </xsl:template>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
    </p:xslt>
    
    <cx:eval name="modify" detailed="true">
      <p:input port="pipeline">
        <p:pipe port="xpl" step="idml_modify"/>
      </p:input>
      <p:input port="source">
        <p:pipe port="result" step="stylesheet"/>
        <p:pipe port="result" step="idml-source"/>
        <p:pipe port="result" step="wrap-external-sources"/>
        <p:pipe port="result" step="parameters"/>
      </p:input>
      <p:input port="options">
        <p:pipe port="result" step="options"/>
      </p:input>
    </cx:eval>
    
    <p:unwrap match="/cx:document[@port eq 'result']"/>
    
     <tr:xslt-mode msg="yes" mode="idml2xml:export" name="export">
      <p:input port="parameters"><p:pipe step="consolidate-params" port="result" /></p:input>
      <p:input port="stylesheet"><p:pipe port="xslt" step="idml_modify"/></p:input>
      <p:input port="models"><p:empty/></p:input>
      <p:with-option name="prefix" select="'idml_modify/05'"/>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      <p:with-param name="srcpaths" select="'no'"/>
      <p:with-param name="zip-file-uri" select="$target-uri"/>
    </tr:xslt-mode>
    
    <p:sink/>
    
    <p:xslt name="zip-manifest" cx:depends-on="export">
      <p:input port="source">
        <p:pipe port="result" step="unzip-idml"/>
        <p:pipe port="result" step="export">
          <p:documentation>Just in order to get the dependency graph correct. 
            (Zip might start prematurely otherwise.)</p:documentation>
        </p:pipe>
      </p:input>
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
             <xsl:template match="/">
                <c:zip-manifest>
                  <xsl:apply-templates select="c:file[@name= 'mimetype']"/>
                  <xsl:apply-templates select="collection()//c:files/*"/>
                </c:zip-manifest>
               
            </xsl:template>
             <xsl:template match="c:file[@name= 'mimetype']" priority="2">
              <c:entry name="{@name}" href="{concat(base-uri(..), @name)}" compression-method="deflate" compression-level="default"/>
            </xsl:template>
            <xsl:template match="*:entry">
              <c:entry name="{replace(replace(@name, '%5B', '['), '%5D', ']')}" href="{@href}" compression-method="deflate" compression-level="default"/>
            </xsl:template>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
    </p:xslt>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="'idml_modify/07.zip-manifest'"/>
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
    </tr:store-debug>
    
    <p:sink/>
    
    <p:xslt name="zip-file-uri" template-name="main" cx:depends-on="zip-manifest">
      <p:with-param name="idml-target-uri" select="$target-uri"/>
      <p:input port="source">
        <p:empty/>
      </p:input>
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
            <xsl:param name="idml-target-uri" required="yes" as="xs:string" />
            <xsl:template name="main">
              <xsl:variable name="result" as="element(c:result)">
                <c:result>
                    <xsl:value-of select="$idml-target-uri"/>
                </c:result>
              </xsl:variable>
              <xsl:message select="concat('idml_modify: modified idml will be stored in ', $result)"/>
              <xsl:sequence select="$result"/>
            </xsl:template>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
    </p:xslt>
    
     <p:sink/>
    
    <tr:zip name="zip" cx:depends-on="zip-file-uri" compression-method="deflated" compression-level="default" command="create">
      <p:with-option name="href" select="/c:result" >
        <p:pipe port="result" step="zip-file-uri"/>
      </p:with-option>
      <p:input port="source">
        <p:pipe step="zip-manifest" port="result"/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="concat($debug-dir-uri, '/idml_modify')"/>
    </tr:zip>
   
      <p:choose cx:depends-on="zip">
      <p:when test="not($debug = 'yes')">
        <cxf:delete recursive="true" fail-on-error="false">
          <p:with-option name="href" select="/c:files/@xml:base">
            <p:pipe step="unzip-idml" port="result"/>
          </p:with-option>
        </cxf:delete>
        <cxf:delete recursive="true" fail-on-error="false">
          <p:with-option name="href" select="replace(/c:files/@xml:base, '\.tmp/?$', '.out')">
            <p:pipe step="unzip-idml" port="result"/>
          </p:with-option>
        </cxf:delete>
      </p:when>
      <p:otherwise>
        <p:sink>
          <p:input port="source">
            <p:pipe port="result" step="zip-manifest"/>
          </p:input>
        </p:sink>
      </p:otherwise>
    </p:choose>

    <p:identity name="fwd-zip">
      <p:input port="source">
        <p:pipe port="result" step="zip"/>
      </p:input>
    </p:identity>

   <p:sink/>  
    
  </p:group>
  
  <p:sink/>  
  
</p:declare-step>
