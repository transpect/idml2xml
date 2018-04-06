<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:idml2xml="http://transpect.io/idml2xml"
  xmlns:hub = "http://transpect.io/hub"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:tr="http://transpect.io"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  version="1.0"
  name="mathtype2mml"
  type="idml2xml:mathtype2mml">

  <p:input port="source" primary="true">
    <p:documentation>The result of mode idml2xml:XML-Hubformat-remap-para-and-span"</p:documentation>
  </p:input>
  <p:input port="params">
    <p:documentation>The params output port of idml2xml tagged2hub</p:documentation>
  </p:input>
  <p:input port="custom-font-maps" primary="false" sequence="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>A sequence of &lt;symbols&gt; documents, containing mapped characters as found in the regular docs2hub fontmaps.</p>
      <p>Each &lt;symbols&gt; is required to contain the name of its font-family as an attribute @name.</p>
      <p>Example, the value of @char is the unicode character that will be in the mml output:</p>
      <pre>&lt;symbols name="Times New Roman">
          &lt;symbol number="002F" entity="&#x002f;" char="&#x002f;"/>
        &lt;/symbols></pre>
      <p>If the base name of the base URI’s file name part is not identical with the font name as encoded in MTEF, 
      you need to give the converter a hint by adding an attribute <code>/symbols/@mathtype-name</code>.</p>
    </p:documentation>
    <p:empty/>
  </p:input>

  <p:output port="result" primary="true">
    <p:documentation>The same basic structure as the primary source of the current step, but with equation pictures replaced with MathML</p:documentation>
    <p:pipe port="result" step="convert-mathtype2mml"/>
  </p:output>
  <p:output port="report" sequence="true">
    <p:pipe port="report" step="convert-mathtype2mml"/>
  </p:output>

  <p:serialization port="result" omit-xml-declaration="false"/>
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  <p:option name="active" required="false" select="'yes'">
    <p:documentation>see corresponding documentation for idml2hub.
    Additionally append '+try-all-pict-wmf' to try conversion
    of all referenced '*.wmf' files in idml/images/</p:documentation>
  </p:option>
  <p:option name="sources" required="false" select="$mathtype2mml">
    <p:documentation>see documentation for 'active' in idml2hub</p:documentation>
  </p:option>
  <p:option name="source-pi" required="false" select="'no'"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/calabash-extensions/mathtype-extension/xpl/mathtype2mml-declaration.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>

  <p:identity name="idml2xml-font-maps">
    <p:input port="source">
      <p:document href="http://transpect.io/fontmaps/MT_Extra.xml"/>
      <p:document href="http://transpect.io/fontmaps/Symbol.xml"/>
      <p:document href="http://transpect.io/fontmaps/Webdings.xml"/>
      <p:document href="http://transpect.io/fontmaps/Wingdings.xml"/>
      <p:document href="http://transpect.io/fontmaps/Wingdings_2.xml"/>
      <p:document href="http://transpect.io/fontmaps/Wingdings_3.xml"/>
      <p:document href="http://transpect.io/fontmaps/Euclid_Extra.xml"/>
      <p:document href="http://transpect.io/fontmaps/Euclid_Fraktur.xml"/>
      <p:document href="http://transpect.io/fontmaps/Euclid_Math_One.xml"/>
      <p:document href="http://transpect.io/fontmaps/Euclid_Math_Two.xml"/>
    </p:input>
  </p:identity>
  
  <p:sink/>

  <p:identity>
    <p:input port="source">
      <p:pipe port="source" step="mathtype2mml"/>
    </p:input>
  </p:identity>
  
  <cx:message>
    <p:with-option name="message"
      select="'############### debug: ', $debug, ' active: ', $active"/>
  </cx:message>
  
  <p:choose name="convert-mathtype2mml">
    <p:when test="$active != 'no'">
      <p:output port="result" primary="true">
        <p:pipe port="result" step="store-viewport"/>
      </p:output>
      <p:output port="report" sequence="true">
        <p:pipe port="result" step="extract-errors"/>
      </p:output>
      <p:variable name="basename" select="/*:hub/*:info/*:keywordset/*:keyword[@role = 'source-basename']"/>
      <p:viewport
        match="//*:mediaobject[*:imageobject/@role = 'hub:embedded'][matches(*:imageobject/*:imagedata/@fileref, '\.(wmf)$', 'i')]"
        name="mathtype2mml-viewport">
        <p:variable name="wmf-id" select="*:mediaobject/*:imageobject/*:imagedata/@xml:id">
         <p:pipe port="current" step="mathtype2mml-viewport"/>
        </p:variable>
        <p:variable name="wmf-href"
          select="if ($wmf-id)
                    then *:mediaobject/*:imageobject/*:imagedata/@fileref
                    else 'no-image-found'">
          <p:pipe port="current" step="mathtype2mml-viewport"/>
        </p:variable>
        <p:choose>
          <p:when test="$debug = 'yes'">
            <cx:message>
              <p:with-option name="message"
                select="'wmf:', $wmf-id, ' wmf-href:', $wmf-href"/>
            </cx:message>
          </p:when>
          <p:otherwise>
            <p:identity/>
          </p:otherwise>
        </p:choose>

        <p:try>
          <p:group>
            <p:group name="convert-wmf">
              <p:output port="result"/>
              <p:choose>
                <p:when test="matches($active, 'wmf')">
                  <tr:mathtype2mml>
                    <p:input port="additional-font-maps">
                      <p:pipe port="result" step="idml2xml-font-maps"/>
                      <p:pipe port="custom-font-maps" step="mathtype2mml"/>
                    </p:input>
                    <p:with-option name="href" select="$wmf-href"/>
                    <p:with-option name="debug" select="$debug"/>
                    <p:with-option name="debug-dir-uri" select="concat($debug-dir-uri, '/idml2xml/', $basename, '/')"/>
                  </tr:mathtype2mml>
                  <p:insert match="mml:math" position="first-child">
                    <p:input port="insertion">
                      <p:inline><wrap-mml><?tr M2M_211 MathML equation source:wmf?></wrap-mml></p:inline>
                    </p:input>
                  </p:insert>
                </p:when>
                <p:otherwise>
                  <!-- since $active is not 'wmf', c:errors will trigger other conversion but not be compared to those results -->
                  <p:identity>
                    <p:input port="source">
                      <p:inline>
                        <c:errors>
                          <c:error/>
                        </c:errors>
                      </p:inline>
                    </p:input>
                  </p:identity>
                </p:otherwise>
              </p:choose>
            </p:group>
            
            <p:identity name="chosen-mml"/>
            <p:insert match="*:imageobject[@role = 'hub:embedded'][matches(*:imagedata/@fileref, '\.(wmf)$', 'i')]/*:imagedata" position="first-child">
              <p:input port="source">
                <p:pipe port="current" step="mathtype2mml-viewport"/>
              </p:input>
              <p:input port="insertion">
                <p:pipe port="result" step="chosen-mml"/>
              </p:input>
            </p:insert>
           
          </p:group>
          <p:catch>
            <cx:message>
              <p:with-option name="message" select="'catch :(', node()"/>
            </cx:message>
            <p:identity/>
          </p:catch>
        </p:try>
      </p:viewport>
      
      <p:unwrap match="wrap-mml"/>

      <tr:store-debug name="store-viewport">
        <p:with-option name="pipeline-step" select="concat('idml2xml/', $basename, '-mathtype-converted')"/>
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>  

      <p:sink/>
      
      <p:identity>
        <p:input port="source">
          <p:pipe port="result" step="store-viewport"/>
        </p:input>
      </p:identity>
      
      <p:choose name="extract-errors">
        <p:when test="exists(//c:error)">
          <p:output port="result" primary="true" sequence="true"/>
          <p:wrap-sequence wrapper="c:errors">
            <p:input port="source" select="//c:error"></p:input>
          </p:wrap-sequence>
          <p:add-attribute match="/*" attribute-name="tr:rule-family" attribute-value="idml2xml_mathtype2mml"/>
        </p:when>
        <p:otherwise>
          <p:output port="result" primary="true" sequence="true"/>
          <p:identity>
            <p:input port="source">
              <p:inline>
                <c:ok tr:rule-family="idml2xml_mathtype2mml"/>
              </p:inline>
            </p:input>
          </p:identity>
        </p:otherwise>
      </p:choose>
    </p:when>
    <p:otherwise>
      <p:output port="result" primary="true"/>
      <p:output port="report" sequence="true">
        <p:inline>
          <c:ok tr:rule-family="idml2xml_mathtype2mml"/>
        </p:inline>
      </p:output>
      <p:identity/>
    </p:otherwise>
  </p:choose>
  
  <p:sink/>
  
</p:declare-step>