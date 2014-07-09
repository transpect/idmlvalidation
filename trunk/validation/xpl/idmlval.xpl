<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c ="http://www.w3.org/ns/xproc-step"  
  xmlns:cx ="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl ="http://www.w3.org/1999/XSL/Transform" 
  xmlns:letex ="http://www.le-tex.de/namespace"
  version="1.0"
  name="idml-validation"
  type="letex:idml-validation"
  >

  <p:option name="idmlfile" required="true"/>

  <!-- option validate-regex:
       choose regex for files and in which directories idmlval should validate -->
  <p:option name="validate-regex" select="'(designmap|Resources|XML|MasterSpreads|Spreads|Stories)'" />

  <p:output port="result" primary="true">
    <p:pipe step="val-component-wrapper" port="result"/>
  </p:output>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.le-tex.de/calabash-extensions/ltx-lib.xpl" />
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
      <p:pipe step="val-component" port="text" />
    </p:output>

    <p:xslt name="rng-selection">
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
            <xsl:param name="base-uri" />
            <xsl:variable name="dom-version"
              select="document(concat($base-uri,'/designmap.xml'))/*/@DOMVersion"/>
            <xsl:template match="/c:file">
              <c:result>
                <xsl:value-of select="$dom-version, '/'" separator=""/>
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
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>

    <p:load name="load">
      <p:with-option name="href" select="resolve-uri(/c:file/@name, base-uri())">
        <p:pipe step="val-components" port="current"/>
      </p:with-option>
    </p:load>

    <letex:validate-with-rng-sch name="val-component">
      <p:with-option name="rngfile" 
        select="resolve-uri(
                  concat('../schema/rng/', /c:result), 
                  static-base-uri()
                )">
        <p:pipe step="rng-selection" port="result"/>
      </p:with-option>
      <p:with-option name="info-messages" select="'true'" />
    </letex:validate-with-rng-sch>
    <p:sink/>

  </p:for-each>

  <p:wrap-sequence group-adjacent="true()" wrapper="c:results" name="val-component-wrapper"/>

  <p:sink/>

</p:declare-step>