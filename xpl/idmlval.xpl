<?xml version="1.0" encoding="utf-8"?>
<p:declare-step version="1.0"
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tr="http://transpect.io"
  xmlns:tr-internal="http://transpect.io/internal"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl" 
  name="idml-validation"
  type="tr:idml-validation"
  >

  <p:option name="idmlfile" required="true"/>
  <p:option name="interface-language" select="'en'"/>
  <p:option name="always-use-schematron-category" select="''"/><!-- 'info', 'warn', 'error'  -->
  <p:option name="status-dir-uri" required="false" select="resolve-uri('status')"/>

  <!-- option validate-regex:
       choose regex for files and in which directories idmlvalidation should validate -->
  <p:option name="validate-regex" select="'(designmap|Resources|XML|MasterSpreads|Spreads|Stories)'" />
  <p:option name="domversion" select="''"/>

  <p:output port="result" primary="true">
    <p:pipe port="result" step="val-component-wrapper"/>
  </p:output>

  <p:output port="report">
    <p:pipe port="result" step="create-report"/>
  </p:output>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  <p:import href="http://transpect.io/calabash-extensions/rng-extension/xpl/rng-schematron.xpl" />
  <p:import href="http://transpect.io/calabash-extensions/unzip-extension/internal-unzip-declaration.xpl" />

  <p:string-replace name="start-msg-replace" match="file">
    <p:with-option name="replace" select="concat('''', replace($idmlfile, '^.+/', ''), '''')"/>
    <p:input port="source">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting validation of IDML file <file/></c:message>
          <c:message xml:lang="de">Beginne mit Validierung der IDML-Datei <file/></c:message>
        </c:messages>
      </p:inline>
    </p:input>    
  </p:string-replace>

  <tr:simple-progress-msg name="start-msg" file="idml-val-start.txt">
    <p:input port="msgs">
      <p:pipe port="result" step="start-msg-replace"/>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

  <tr-internal:unzip name="unzip">
    <p:with-option name="zip" select="$idmlfile" />
    <p:with-option name="dest-dir" select="concat($idmlfile, '.tmp')"/>
    <p:with-option name="overwrite" select="'yes'" />
  </tr-internal:unzip>

  <cx:message>
    <p:with-option name="message" 
      select="'IDML Validation&#xa;Successfully extracted ', 
              tokenize($idmlfile, '/')[last()],
              '. Files in idml container: ', count(/c:files/*), 
              ' (stories: ', count(/c:files/*[matches(@name, '^Stories')]), ')',
              '&#xa;Files/Folder regex: ', $validate-regex, 
              '&#xa;Validating ', 
              count(/c:files
                      /c:file
                        [matches(
                          @name, 
                          concat('^', $validate-regex))
                        ]
                   ),
              ' files ...'"/>
  </cx:message>
  
  <p:for-each name="val-components">
    <p:iteration-source 
      select="/c:files
                /c:file
                  [matches(
                    @name, 
                    concat('^', $validate-regex))
                  ]" />
    <p:output port="result" primary="true">
      <p:pipe step="val-component" port="result" />
    </p:output>

    <p:xslt name="rng-selection">
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
            <xsl:param name="base-uri" />
            <xsl:param name="domversion" />
            <xsl:variable name="designmap-domversion"
              select="document(concat($base-uri,'/designmap.xml'))/*/@DOMVersion"/>
            <xsl:template match="/c:file">
              <c:result designmap-domversion="{$designmap-domversion}">
                <xsl:value-of select="($domversion, $designmap-domversion)[. ne ''][1], '/'" separator=""/>
                <xsl:choose>
                  <xsl:when test="matches(@name, '^Stories')">Stories/Story.rng</xsl:when>
                  <xsl:when test="matches(@name, '^Spreads/')">Spreads/Spread.rng</xsl:when>
                  <xsl:when test="matches(@name, '^MasterSpreads/')">MasterSpreads/MasterSpread.rng</xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="replace(@name, 'xml$', 'rng')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </c:result>
            </xsl:template>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
      <p:with-param name="base-uri" select="base-uri()"/>
      <p:with-param name="domversion" select="$domversion"/>
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>

    <p:choose name="val-component">
      <p:when test="doc-available(resolve-uri(concat('../schema/rng/', /c:result), static-base-uri()))">
        <p:output port="result">
          <p:pipe port="text" step="rng-val"/>
        </p:output>
        <p:load name="load">
          <p:with-option name="href" select="resolve-uri(/c:file/@name, base-uri())">
            <p:pipe step="val-components" port="current"/>
          </p:with-option>
        </p:load>

        <tr:validate-with-rng-sch name="rng-val">
          <p:with-option name="rngfile" 
            select="resolve-uri(
                    concat('../schema/rng/', /c:result), 
                    static-base-uri()
                  )">
            <p:pipe step="rng-selection" port="result"/>
          </p:with-option>
          <p:with-option name="info-messages" select="'true'" />
        </tr:validate-with-rng-sch>
        <p:sink/>

      </p:when>
      <p:otherwise>
        <p:output port="result"/>
        <p:identity>
          <p:input port="source">
            <p:inline><c:result>RelaxNG schema file for the given DOMVersion is not available.</c:result></p:inline>
          </p:input>
        </p:identity>
      </p:otherwise>
    </p:choose>
  </p:for-each>

  <p:wrap-sequence group-adjacent="true()" wrapper="c:results" name="val-component-wrapper"/>
<!--
  <p:choose name="idmlval-result">
    <p:when test="every $v in /c:results/c:result satisfies contains($v, 'DOMVersion is not available')">
      <p:output port="result"/>
      <p:identity>
        <p:input port="source">
          <p:inline><c:results><c:result>DOMVersion is not available.</c:result></c:results></p:inline>
        </p:input>
      </p:identity>
    </p:when>
    <p:otherwise>
      <p:output port="result"/>
      <p:identity/>
    </p:otherwise>
  </p:choose>
-->
  <p:xslt name="create-report">
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0">
          <xsl:param name="idmlfile"/>
          <xsl:param name="interface-language"/>
          <xsl:param name="validate-regex"/>
          <xsl:param name="always-use-schematron-category" select="''"/>
          <xsl:template match="c:results">
            <svrl:schematron-output tr:rule-family="idml" tr:step-name="idml-validation">
              <svrl:active-pattern document="{$idmlfile}" id="idml-validation" name="idml-validation"/>
              <svrl:successful-report test="(: unknown :)" id="idml-validation" role="{($always-use-schematron-category[. != ''], if(contains(., 'DOMVersion is not available')) then 'info' else 'error')[1]}" location="/">
                <svrl:text>
                  <span xmlns="http://purl.oclc.org/dsdl/schematron" class="srcpath">
                    <xsl:value-of select="'BC_orphans'"/>
                  </span>
                  <xsl:choose>
                    <xsl:when test="contains(., 'RelaxNG schema file for the given DOMVersion is not available')">
                      <xsl:choose>
                        <xsl:when test="$interface-language eq 'de'">
                          Für die interne DOM-Version zur IDML-Datei sind keine Schema-Daten hinterlegt.
                          <br xmlns="http://www.w3.org/1999/xhtml"/>
                          IDML-Validierung konnte nicht durchgeführt werden.
                          <br xmlns="http://www.w3.org/1999/xhtml"/>
                          Bitte den Verantwortlichen für das transpect-Projekt informieren.
                        </xsl:when>
                        <xsl:otherwise>
                          There is no schema file for the current IDML DOM-version available. Validation stopped.
                          <br xmlns="http://www.w3.org/1999/xhtml"/>
                          Please contact the maintainer of the project.
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:variable name="messages" as="xs:string+"
                        select="//*:rng-sch-validation-report/tokenize(string-join(descendant::text(), ''), '&#xa;')[normalize-space(.)]"/>
                      <xsl:choose>
                        <xsl:when test="$interface-language eq 'de'">
                          Es wurden ingesamt <xsl:value-of select="count($messages)"/> Validierungsfehler festgestellt. Siehe nachfolgende Auflistung.
                        </xsl:when>
                        <xsl:otherwise>
                          There are <xsl:value-of select="count($messages)"/> validation problems. See the following list.
                        </xsl:otherwise>
                      </xsl:choose>
                      <br xmlns="http://www.w3.org/1999/xhtml"/><br xmlns="http://www.w3.org/1999/xhtml"/>
                      <xsl:variable name="nondistinct-messages" as="element()?">
                        <msgs>
                          <xsl:for-each select="$messages">
                            <msg text="{replace(
                                          replace(
                                            replace(
                                              replace(., '^(.+)( Erlaubt ist nur das Attr| Erwartet wird das Element).+$', '$1'),
                                              'Stories/Story_[^.]+.xml',
                                              'Stories/'
                                              ),
                                            '( lineNumber: \d+; columnNumber: \d+;| ist an diesem Element)',
                                            ''),
                                          concat('^.+/(', $validate-regex, '/|designmap.xml)'), 
                                          '$1'
                                        )}"/>
                          </xsl:for-each>
                        </msgs>
                      </xsl:variable>
                      <xsl:for-each select="distinct-values($nondistinct-messages//*:msg/@text)">
                        <xsl:sort/>
                        <xsl:value-of select="count($nondistinct-messages//*:msg[@text = current()])"/>x in <xsl:value-of select="."/>
                        <br xmlns="http://www.w3.org/1999/xhtml"/>
                      </xsl:for-each>
                    </xsl:otherwise>
                  </xsl:choose>
                </svrl:text>
              </svrl:successful-report>
            </svrl:schematron-output>
          </xsl:template>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:with-param name="idmlfile" select="$idmlfile"/>
    <p:with-param name="interface-language" select="$interface-language"/>
    <p:with-param name="validate-regex" select="$validate-regex"/>
    <p:with-param name="always-use-schematron-category" select="$always-use-schematron-category"/>
  </p:xslt>

  <p:sink/>

  <p:string-replace name="success-msg-replace" match="file">
    <p:with-option name="replace" select="concat('''', replace($idmlfile, '^.+/', ''), '''')"/>
    <p:input port="source">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Successfully finished validation of IDML file <file/></c:message>
          <c:message xml:lang="de">IDML-Validierung von <file/> erfolgreich abgeschlossen</c:message>
        </c:messages>
      </p:inline>
    </p:input>    
  </p:string-replace>
  
  <tr:simple-progress-msg name="success-msg" file="idml-val-success.txt" cx:depends-on="create-report">
    <p:input port="msgs">
      <p:pipe port="result" step="success-msg-replace"/>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

  <p:sink/>

</p:declare-step>
