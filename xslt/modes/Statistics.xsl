<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
  version="2.0"
  xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs = "http://www.w3.org/2001/XMLSchema"
  xmlns:aid = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5 = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  exclude-result-prefixes = "xs"
>
  <xsl:template match="/" mode="idml2xml:Statistics">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
      <head>
        <title>Summary of <xsl:value-of select="$idml2xml:basename, '.idml'" separator=""/></title>
        <xsl:call-template name="StatisticsCSS"/>
      </head>
      <body>
        <h1>Table of Content</h1>
        <ul>
          <li><a href="#structdata">Structure objects and summary</a></li>
          <li>Styles</li>
          <ul>
            <li><a href="#parastyles">Paragraphs</a></li>
            <li><a href="#charstyles">Characters</a></li>
            <li><a href="#tabstyles">Tables</a></li>
            <li><a href="#objstyles">Objects</a></li>
          </ul>
          <li><a href="#tags">Tags</a></li>
          <li><a href="#mapping">Mapping</a></li>
          <ul>
            <li><a href="#importmap">ImportMap</a></li>
            <li><a href="#exportmap">ExportMap</a></li>
          </ul>
          <li><a href="#images">Images</a></li>
          <li><a href="#fonts">Fonts</a></li>
        </ul>
        <h1 id="structdata">Structure objects and summary</h1>
        <table>
          <thead>
            <tr>
              <th>Key</th>
              <th>Value</th>
            </tr>
          </thead>
          <tbody>
            <xsl:if test="count( //@PrimaryLanguageName ) eq 1">
              <tr>
                <th>Primary language (Sublanguage)</th>
                <td><xsl:value-of select="idml2xml:substr( 'a', /Document/Language/@PrimaryLanguageName, '$ID/' )"/> (<xsl:value-of select="idml2xml:substr( 'a', /Document/Language/@SublanguageName, '$ID/' )"/>)</td>
              </tr>
            </xsl:if>
            <tr>
              <th>Pages
	          <br />Master spreads (pages)
		  <br /> – Names (usage)<xsl:for-each select="//MasterSpread"><br/></xsl:for-each>
	          Spreads
	          <br />Stories
	          <br />Textframes
	      </th>
              <td>
                <xsl:value-of select="count( //Page[ not( parent::MasterSpread ) ] )"/><br />
                <xsl:value-of select="concat( count( //MasterSpread ), ' (', count( //MasterSpread/Page) ,')')"/><br />
		<xsl:for-each select="//MasterSpread">
		  <xsl:value-of select="concat( ' - ', @Name, ' (', count(//Page[ not( parent::MasterSpread ) ][@AppliedMaster eq current()/@Self]), ')')"/><br />
		</xsl:for-each>
                <xsl:value-of select="count( //Spread )"/><br />
                <xsl:value-of select="count( //Story )"/><br />
                <xsl:value-of select="count( //TextFrame )"/></td>
            </tr>
            <tr>
              <th>Document dimension</th>
              <td><xsl:value-of select="'Width: ≈', idml2xml:substr( 'b', xs:string( //DocumentPreference/@PageWidth * xs:double('0.353') ), '.' ), 'mm ≈', idml2xml:substr( 'b', //DocumentPreference/@PageWidth, '.' ), 'Pt'"/><br /><xsl:value-of select="'Height: ≈', idml2xml:substr( 'b',  xs:string( //DocumentPreference/@PageHeight * xs:double('0.353') ), '.' ), 'mm ≈', idml2xml:substr( 'b', //DocumentPreference/@PageHeight, '.' ), 'Pt'"/></td>
            </tr>
            <tr>
              <th>Multi-Columns</th>
              <td><xsl:value-of select="if( //@ColumnCount[ xs:integer(.) gt 1 ] ) then ('yes'(:, distinct-values( for $i in //@ColumnCount[ xs:integer(.) gt 1 ] return (', ', $i, ' columns' ) ) :)) else 'no'" separator=""/></td>
            </tr>
            <tr>
              <th>Tables</th>
              <xsl:variable name="cntTables" select="count( //Table )" as="xs:integer+"/>
              <td><xsl:value-of select="$cntTables"/> (
              <xsl:value-of select="'ø', 
                count( //Row ) div ( if( $cntTables = 0 ) then 1 else $cntTables ) , 'Rows and ø', 
                count( //Column ) div ( if( $cntTables = 0 ) then 1 else $cntTables ), 'Columns'"/>)</td>
            </tr>
            <tr>
              <th>Images (linked)<br /> – EPS<br /> – PDF<br /> – WMF<br /> – Image</th>
              <td><xsl:value-of select="count( //*[name() = $idml2xml:shape-element-names] )"/> (<xsl:value-of select="count( //*[name() = $idml2xml:shape-element-names][descendant::Link/@LinkResourceURI] )"/>)<br />
	          <xsl:value-of select="count( //*[name() = $idml2xml:shape-element-names][exists(EPS)] )"/><br />
	          <xsl:value-of select="count( //*[name() = $idml2xml:shape-element-names][exists(PDF)] )"/><br />
	          <xsl:value-of select="count( //*[name() = $idml2xml:shape-element-names][exists(WMF)] )"/><br />
	          <xsl:value-of select="count( //*[name() = $idml2xml:shape-element-names][exists(Image)] )"/></td>
            </tr>
            <tr>
              <th>Paragraphs</th>
              <td><xsl:value-of select="count( //ParagraphStyleRange )"/></td>
            </tr>
            <tr>
              <th>Character style ranges</th>
              <td><xsl:value-of select="count( //CharacterStyleRange )"/></td>
            </tr>
            <tr>
              <th>Footnotes</th>
              <td><xsl:value-of select="count( //Footnote  )"/></td>
            </tr>
            <tr>
              <th>Hyperlinks</th>
              <td><xsl:value-of select="count( //HyperlinkTextSource ) + count( //HyperlinkTextDestination )"/></td>
            </tr>
            <tr>
              <xsl:variable name="indexterms" select="//PageReference" />
              <xsl:variable name="indexlvl1" select="idml2xml:countIndexterms( 1, $indexterms )"/>
              <xsl:variable name="indexlvl2" select="idml2xml:countIndexterms( 2, $indexterms )"/>
              <xsl:variable name="indexlvl3" select="idml2xml:countIndexterms( 3, $indexterms )"/>
              <xsl:variable name="indexlvl4" select="idml2xml:countIndexterms( 4, $indexterms )"/>
              <th>Indexterms, occurence as unit (sum incl. subentries)<br /> – Primary<br /> – Secondary<br /> – Tertiary<br /> – Quaternary</th>
              <td><xsl:value-of select="count( $indexterms )"/> (<xsl:value-of select="$indexlvl1 + $indexlvl2 + $indexlvl3 + $indexlvl4"/>)<br />
                <xsl:value-of select="$indexlvl1"/><br />
                <xsl:value-of select="$indexlvl2"/><br />
                <xsl:value-of select="$indexlvl3"/><br />
                <xsl:value-of select="$indexlvl4"/><br /></td>
            </tr>
            <tr>
              <th>Notes</th>
              <td><xsl:value-of select="count( //Note )"/></td>
            </tr>
            <tr>
              <th><a href="#tags">XML elements</a></th>
              <xsl:variable name="cntXMLElement" select="count( //XMLElement )"/>
              <td><xsl:value-of select="$cntXMLElement"/> ( ø <xsl:value-of select="$cntXMLElement div ( count( //XMLAttribute ) + 1 (: int div by zero :) )"/> attributes)</td>
            </tr>
            <tr>
              <th>Embedded/linked objects</th>
              <td><xsl:value-of select="count( //DataSourceFile )"/></td>
            </tr>
            <tr>
              <th>Rotated elements (e.g. images)</th>
              <td><xsl:value-of select="count( //@ItemTransform[ not( starts-with( ., '1 0 0' ) ) ] ), 'of', count( //@ItemTransform[starts-with( ., '1 0 0' ) ] ), 'total'"/></td>
            </tr>
            <tr>
              <th>Document users</th>
              <td><xsl:value-of select="for $u in //DocumentUser/@UserName return ( idml2xml:substr( 'a', $u, '$ID/' ), ', ' )" separator="" /></td>
            </tr>
          </tbody>
        </table>
        <h1>Styles</h1>
        <table>
          <thead>
            <tr>
              <th id="parastyles" class="supercap">Paragraph Style</th>
              <th id="charstyles" class="supercap">Character Style</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <table>
                  <thead>
                    <tr><!-- Paragraphs -->
                      <th>Name</th>
                      <th>Used in stories</th>
                    </tr>
                  </thead>
                  <tbody>
                    <xsl:for-each select="//ParagraphStyle">
                      <tr>
                        <th><xsl:value-of select="idml2xml:substr( 'a', @Name, '$ID/' )"/></th>
                        <td><xsl:value-of select="count( //idPkg:Story//ParagraphStyleRange[@AppliedParagraphStyle eq concat( 'ParagraphStyle/', current()/@Name ) ] )"/></td>
                      </tr>
                    </xsl:for-each>
                  </tbody>
                </table>
              </td>
              <td>
                <table>
                  <thead>
                    <tr><!-- Characters -->
                      <th>Name</th>
                      <th>Used in stories</th>
                    </tr>
                  </thead>
                  <tbody>
                    <xsl:for-each select="//CharacterStyle">
                      <tr>
                        <th><xsl:value-of select="idml2xml:substr( 'a', @Name, '$ID/' )"/></th>
                        <td><xsl:value-of select="count( //idPkg:Story//CharacterStyleRange[@AppliedCharacterStyle eq concat( 'CharacterStyle/', current()/@Name ) ] )"/></td>
                      </tr>
                    </xsl:for-each>
                  </tbody>
                </table>
              </td>
            </tr>
          </tbody>
        </table>
        <table>
          <thead>
            <tr>
              <th id="tabstyles" class="supercap">Table Style</th>
              <th id="objstyles" class="supercap">Object Style</th>
            </tr>
          </thead>
            <tr>
              <td>
                <table>
                  <thead>
                    <tr><!-- Tables -->
                      <th>Name</th>
                      <th>Used in stories</th>
                    </tr>
                  </thead>
                  <tbody>
                    <xsl:for-each select="//TableStyle">
                      <tr>
                        <th><xsl:value-of select="idml2xml:substr( 'a', @Name, '$ID/' )"/></th>
                        <td><xsl:value-of select="count( //idPkg:Story//Table[@AppliedTableStyle eq concat( 'TableStyle/', current()/@Name ) ] )"/></td>
                      </tr>
                    </xsl:for-each>
                  </tbody>
                </table>
              </td>
              <td>
                <table>
                  <thead>
                    <tr><!-- Objects -->
                      <th>Name</th>
                      <th>Used in stories</th>
                    </tr>
                  </thead>
                  <tbody>
                    <xsl:for-each select="//ObjectStyle">
                      <tr>
                        <th><xsl:value-of select="idml2xml:substr( 'a', @Name, '$ID/' )"/></th>
                        <td><xsl:value-of select="count( //idPkg:Story//@AppliedObjectStyle[ . eq concat( 'ObjectStyle/', current()/@Name ) ] )"/></td>
                      </tr>
                    </xsl:for-each>
                  </tbody>
                </table>
              </td>
            </tr>
        </table>				
        <h1 id="tags">Tags</h1>
        <table>
          <thead>
            <tr>
              <th class="position"></th>
              <th>Tagname</th>
              <th class="middle">Color</th>
              <th class="middle">Used</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="//XMLTag">
              <tr>
                <td class="position"><xsl:value-of select="position()"/></td>
                <th><xsl:value-of select="@Name"/></th>
                <xsl:variable name="tagColor" select="current()//TagColor"/>
                <td class="middle" style="background-color: {$tagColor};"><xsl:value-of select="$tagColor"/></td>
                <td class="middle"><xsl:value-of select="count( //XMLElement[@MarkupTag eq concat( 'XMLTag/', current()/@Name ) ] )"/></td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
        <h1 id="mapping">Mapping</h1>
                <table>
          <thead>
            <tr>
              <th id="importmap" class="supercap">ImportMap</th>
              <th id="exportmap" class="supercap">ExportMap</th>
            </tr>
          </thead>
            <tr>
              <td>
                <table>
                  <thead>
                    <tr><!-- ImportMap -->
                      <th>Tagname</th>
                      <th>Stylename</th>
                    </tr>
                  </thead>
                  <tbody>
                    <xsl:for-each select="//XMLImportMap">
                      <tr>
                        <th><xsl:value-of select="idml2xml:substr( 'a', @MarkupTag, 'XMLTag/' )"/></th>
                        <td><xsl:value-of select="@MappedStyle"/></td>
                      </tr>
                    </xsl:for-each>

                  </tbody>
                </table>
              </td>
              <td>
                <table>
                  <thead>
                    <tr><!-- ExportMap -->
                      <th>Tagname</th>
                      <th>Stylename</th>
                    </tr>
                  </thead>
                  <tbody>
                    <xsl:for-each select="//XMLExportMap">
                      <tr>
                        <th><xsl:value-of select="idml2xml:substr( 'a', @MarkupTag, 'XMLTag/' )"/></th>
                        <td><xsl:value-of select="@MappedStyle"/></td>
                      </tr>
                    </xsl:for-each>
                  </tbody>
                </table>
              </td>
            </tr>
        </table>
        <!-- Aufnehmen: wurden Bilder gespiegelt? beschnitten? am besten Auflistung aller Bilder mit jeweiligen Bearbeitungen -->
        <h1 id="images">Images</h1>
        <table>
          <thead>
            <tr>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="//Image">
              <tr>
                <td></td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
        <h1 id="fonts">Fonts</h1>
        <table>
          <thead>
            <tr>
              <th>Fontfamily</th>
              <th>Font</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="//FontFamily">
              <tr>
                <th>"<xsl:value-of select="idml2xml:substr( 'a', @Name, '$ID/' )"/>"</th>
                <td>
                <xsl:for-each select="current()//Font">
                  <xsl:value-of select="if( @FullName != '' ) then idml2xml:substr( 'a', @FullName, '$ID/' ) else idml2xml:substr( 'a', @Name, '$ID/' )"/><br />
                </xsl:for-each>
                </td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
        <!-- additional info: list of all KeyboardShortcut -->

        <!-- filename and timestamp -->
        <p><xsl:value-of select="'File: ', $idml2xml:basename, '.idml'" separator=""/><br />
          <xsl:value-of select="'Date:', format-date(current-date(), '[Y]-[M]-[D]')"/><br />
          <xsl:value-of select="'Timestamp:', current-dateTime()"/></p>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template name="StatisticsCSS">
    <style type="text/css">
      /*<![CDATA[*/
        table {width:96%; padding-left:0.5em;}
        thead th, tfoot td {background-color:#CCC;}
        th, td {vertical-align:top; text-align:left; border-bottom:1px solid #CCC;}
        tfoot td {text-align:center;}
        .middle {text-align:center;}
        th.position, td.position {text-align:right; max-width:0.25em; color:#555; padding-right:0.5em;}
        td.position {font-weight:normal;}
        .supercap {color:#FFF; background-color:#000; text-align:center;}
      /*]]>*/
      </style>
  </xsl:template>
  
</xsl:stylesheet>
