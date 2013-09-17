<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c ="http://www.w3.org/ns/xproc-step"  
  xmlns:cx ="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl ="http://www.w3.org/1999/XSL/Transform" 
  xmlns:letex="http://www.le-tex.de/namespace"
  version="1.0"
  name="idml_validation"
  type="idml2xml:idml-validation"
  >

  <p:option name="idmlfile" />

  <!-- option validate-dirs-regex:
       choose in which directories idmlval should look for files to validate -->
  <p:option name="validate-dirs-regex" select="'(Resources|XML|MasterSpreads|Spreads|Stories)'" />

  <p:output port="result" primary="true">
    <p:pipe step="val-component-wrapper" port="result"/>
  </p:output>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.le-tex.de/calabash-extensions/ltx-unzip/ltx-lib.xpl" />
  <p:import href="http://transpect.le-tex.de/rngvalid/rng-schematron.xpl" />

  <letex:unzip name="unzip">
    <p:with-option name="zip" select="$idmlfile" />
    <p:with-option name="dest-dir" select="concat($idmlfile, '.tmp')"/>
    <p:with-option name="overwrite" select="'yes'" />
  </letex:unzip>

  <cx:message>
    <p:with-option name="message" 
      select="'IDML Validation&#xa;Successfully extracted ', 
              tokenize($idmlfile, '/')[last()],
              '. Files in idml container: ', count(/c:files/*), 
              ' (stories: ', count(/c:files/*[matches(@name, '^Stories')]), ')',
              '&#xa;Folder regex: ', $validate-dirs-regex, 
              '&#xa;Validating ', 
              count(/c:files
                      /c:file
                        [matches(
                          @name, 
                          concat('^', $validate-dirs-regex))
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
                    concat('^', $validate-dirs-regex))
                  ]"/>
    <p:output port="result" primary="true">
      <p:pipe step="val-component" port="text" />
    </p:output>
    
    <p:xslt name="rng-selection">
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
            <xsl:template match="/c:file">
              <xsl:choose>
                <xsl:when test="matches(@name, '^Stories')">
                  <c:result>Stories/Story.rng</c:result>
                </xsl:when>
                <xsl:when test="matches(@name, '^Spreads/')">
                  <c:result>Spreads/Spread.rng</c:result>
                </xsl:when>
                <xsl:when test="matches(@name, '^MasterSpreads/')">
                  <c:result>MasterSpreads/MasterSpread.rng</c:result>
                </xsl:when>
                <xsl:otherwise>
                  <c:result>
                    <xsl:value-of select="replace(@name, 'xml$', 'rng')"/>
                  </c:result>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:template>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>

    <p:load name="load">
      <p:with-option name="href" select="resolve-uri(/c:file/@name, base-uri())">
        <p:pipe step="val-components" port="current"/>
      </p:with-option>
    </p:load>

    <letex:validate-with-rng-sch name="val-component">
      <p:with-option name="rngfile" select="resolve-uri(concat('../schema/rng/', /c:result), static-base-uri())">
        <p:pipe step="rng-selection" port="result"/>
      </p:with-option>
      <p:with-option name="info-messages" select="'false'" />
    </letex:validate-with-rng-sch>
    <p:sink/>
  </p:for-each>

  <p:wrap-sequence wrapper="c:results" name="val-component-wrapper"/>

  <p:sink />

  <p:load name="designmap">
    <p:with-option name="href" select="concat(/c:files/@xml:base, 'designmap.xml')">
      <p:pipe step="unzip" port="result"/>
    </p:with-option>
  </p:load>

  <p:sink/>

</p:declare-step>
