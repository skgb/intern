<?xml version="1.0" encoding="utf-8" standalone="yes"?>

<!--

XSLT conversion specification for 'SKGB-Regeln' to OpenDocument
(c) 2015-2016 Segel- und Kanugemeinschaft Brucher Talsperre e. V. SKGB
Proprietary/Confidential. All Rights Reserved.

$Id: regeln2odf.xsl 848 2016-09-07 21:12:19Z aj $

-->


<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:regeln="http://www.skgb.de/2005/regeln" xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" exclude-result-prefixes="regeln html">
	
	<xsl:variable name="version" select="number(0.81)"/><!-- SKGB-Regeln format version -->
	
	<xsl:template name='check-version'>
		
		<xsl:if test="number(/.//regeln:regeln//@version) &lt; $version">
			<xsl:message>
				<xsl:text>Warning: Document Format Version Mismatch! The processed document conforms to version </xsl:text>
				<xsl:value-of select="format-number(number(/.//regeln:regeln//@version), '0.00')"/>
				<xsl:text> of 'SKGB-Regeln', but this XSLT is made for version </xsl:text>
				<xsl:value-of select="format-number($version, '0.00')"/>
				<xsl:text>. The results may not be what you expect.</xsl:text>
			</xsl:message>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name='check-structure'>
		<xsl:for-each select="//regeln:nr/regeln:lit[2]">
			<xsl:message>
				<xsl:text>Warning: Document Structure Mismatch! The processed document conforms to 'SKGB-Regeln', but this XSLT doesn't support the kind of hierarchy it uses for its enumeration of clauses. The transformation results may not be what you expect.</xsl:text>
			</xsl:message>
		</xsl:for-each>
	</xsl:template>
	
	
	<!--xsl:namespace-alias stylesheet-prefix="html" result-prefix="#default"/-->

	<!-- Need to instruct the XSLT processor to use HTML output rules.
		 See http://www.w3.org/TR/xslt#output for more details
	-->
	<xsl:output method="xml" media-type="application/vnd.oasis.opendocument.text" encoding="UTF-8" omit-xml-declaration="no" standalone="yes" indent="no"/><!--  indent="yes"><xsl:strip-space elements="*"/>-->
	<!-- indent or cdata-section-elements ? -->
	<!-- doctype: check out if counting LIs are in fact supported by Strict; check out XHTML5 -->
	
	<xsl:template match="html:*">
		<!--xsl:copy><xsl:apply-templates/></xsl:copy-->
		<!--xsl:element name="{local-name()}" use-attribute-sets="html:href"><xsl:apply-templates/></xsl:element-->
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="html:br">
		<text:line-break/>
	</xsl:template>
	
	<xsl:template match="html:em">
		<text:span text:style-name="Emphasis">
			<xsl:apply-templates/>
		</text:span>
	</xsl:template>
	
	<xsl:template match="html:i">
		<text:span text:style-name="Emphasis">
			<xsl:apply-templates/>
		</text:span>
	</xsl:template>
	
	<xsl:template match="html:b">
		<text:span text:style-name="Strong_20_Emphasis">
			<xsl:apply-templates/>
		</text:span>
	</xsl:template>
	
	<xsl:template match="html:u">
		<text:span text:style-name="Underline_20_Emphasis">
			<xsl:apply-templates/>
		</text:span>
	</xsl:template>
	
	<xsl:template match="/">
		<xsl:call-template name="check-version"/>
		<xsl:call-template name="check-structure"/>
		<!--xsl:processing-instruction name="xml-stylesheet">href="#style" type="text/css"</xsl:processing-instruction-->
		<office:document xml:lang="de" office:version="1.2" office:mimetype="application/vnd.oasis.opendocument.text">
			<office:meta><meta:generator>regeln2odf/<xsl:value-of select="format-number($version, '0.00')"/></meta:generator></office:meta>
			<!--head>
				<title>
					<xsl:value-of select="//regeln:name"/>
					<xsl:text> – SKGB</xsl:text>
					<xsl:if test="//regeln:entwurf">
						<xsl:text> – Entwurf </xsl:text>
						<xsl:value-of select="//regeln:entwurf/@revision"/>
					</xsl:if>
				</title>
				<style type="text/css" id="style">
					<xsl:text></xsl:text>
				</style>
				<link rel="stylesheet" title="Änderungen verbergen" type="text/css" href="data:text/css,ins%2Cins%20*%7Btext-decoration%3Anone%7Ddel%2Cdel%20*%2C.gestrichen%7Bdisplay%3Anone%7D"/>
				<link rel="alternate stylesheet" title="Änderungen zeigen" type="text/css" href="data:text/css,ins%2Cins%20*%7Bbackground%3A%237f7%7Dspan.geaendert%7Bbackground%3A%23ff7%7D"/>
			</head-->

 <office:font-face-decls>
  <style:font-face style:name="FreeSerif" svg:font-family="FreeSerif" style:font-adornments="Regular" style:font-family-generic="roman" style:font-pitch="variable"/>
  <style:font-face style:name="Helvetica Neue" svg:font-family="&apos;Helvetica Neue&apos;" style:font-pitch="variable"/>
 </office:font-face-decls>

 <office:styles>

  <style:default-style style:family="paragraph">
   <style:paragraph-properties fo:hyphenation-ladder-count="no-limit" style:text-autospace="ideograph-alpha" style:punctuation-wrap="hanging" style:line-break="strict" style:tab-stop-distance="1.27cm" style:writing-mode="lr-tb"/>
   <style:text-properties style:use-window-font-color="true" style:font-name="FreeSerif" fo:font-size="12pt" style:text-outline="false" fo:letter-spacing="normal" fo:font-weight="normal" style:font-pitch="variable" style:letter-kerning="true" fo:language="de" fo:country="DE" fo:hyphenation-remain-char-count="2" fo:hyphenation-push-char-count="2"/>
  </style:default-style>
  <style:style style:name="Standard" style:family="paragraph" style:class="text"><!-- "Default Style" -->
   <loext:graphic-properties draw:fill="none"/>
   <style:paragraph-properties fo:line-height="100%">
    <style:tab-stops/>
   </style:paragraph-properties>
   <style:text-properties style:font-name="FreeSerif" fo:font-family="FreeSerif" style:font-style-name="Regular" style:font-family-generic="roman" fo:hyphenate="true" fo:color="#000000"/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Vereinsname" style:family="paragraph" style:parent-style-name="Standard"><!-- SKGB -->
   <style:paragraph-properties fo:text-align="center" fo:margin-top="2.8cm"/>
   <style:text-properties style:font-name="Helvetica Neue" fo:font-size="8pt"/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Entwurfsvermerk" style:family="paragraph" style:parent-style-name="Standard"><!-- Entwurfsvermerk -->
   <style:paragraph-properties fo:text-align="center"/>
   <style:text-properties fo:text-transform="uppercase" fo:font-size="18pt"/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Ausfertigungsvermerk" style:family="paragraph" style:parent-style-name="Standard"><!-- Ausfertigungsvermerk -->
   <style:paragraph-properties fo:margin-top="0.7cm"/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Titel" style:family="paragraph" style:parent-style-name="Standard" style:master-page-name="SKGB-Regeln-Titelseite"><!-- Titel -->
   <style:paragraph-properties fo:text-align="center"/>
   <style:text-properties fo:font-size="15pt"/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Stand" style:family="paragraph" style:parent-style-name="Standard"><!-- Untertitel -->
   <style:paragraph-properties fo:margin-top="0.2cm" fo:margin-bottom="0.3cm" fo:text-align="center"/>
   <style:text-properties/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Praeambel" style:family="paragraph" style:parent-style-name="Standard"><!-- Praeambel -->
   <style:paragraph-properties fo:margin-top="0.5cm" fo:margin-bottom="0.2cm"/>
   <style:text-properties fo:font-style="italic"/>
  </style:style>

  <style:style style:name="SKGB-Regeln-Paragraph-Abstract" style:family="paragraph" style:parent-style-name="Standard" style:hidden="true">
   <style:paragraph-properties fo:margin-left="0.6cm" fo:margin-right="0cm" fo:margin-top="0.4cm" fo:margin-bottom="0cm" loext:contextual-spacing="false" fo:text-indent="-0.6cm" style:auto-text-indent="false" fo:background-color="transparent"/>
   <style:text-properties fo:font-weight="bold"/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Paragraph" style:family="paragraph" style:parent-style-name="SKGB-Regeln-Paragraph-Abstract" style:list-style-name="SKGB-Regeln"><!-- Paragraph-Nummer und -Titel -->
  </style:style>

  <style:style style:name="SKGB-Regeln-Absatz-Abstract" style:family="paragraph" style:parent-style-name="Standard" style:hidden="true">
   <style:paragraph-properties fo:margin-left="0.6cm" fo:margin-right="0cm" fo:margin-top="0.15cm" fo:margin-bottom="0cm" loext:contextual-spacing="false" fo:orphans="2" fo:widows="2" fo:text-indent="0cm" style:auto-text-indent="false" fo:background-color="transparent"/>
  </style:style>
  <style:style style:name="SKGB-Regeln-Absatz" style:family="paragraph" style:parent-style-name="SKGB-Regeln-Absatz-Abstract" style:list-style-name="SKGB-Regeln"><!-- Absatz-Text (bei Numerierung) -->
  </style:style>
  <style:style style:name="SKGB-Regeln-Absatz-single" style:family="paragraph" style:parent-style-name="SKGB-Regeln-Absatz-Abstract" style:list-style-name="SKGB-Regeln"><!-- Absatz-Text (ohne Numerierung) -->
   <style:paragraph-properties fo:margin-left="0.5cm"/>
  </style:style>

  <style:style style:name="SKGB-Regeln-Buchstaben" style:family="paragraph" style:parent-style-name="Standard" style:list-style-name="SKGB-Regeln"><!-- Buchstaben-Text -->
  </style:style>



  <style:style style:name="Emphasis" style:display-name="Emphasis" style:family="text">
   <style:text-properties fo:font-style="italic"/>
  </style:style>
  <style:style style:name="Strong_20_Emphasis" style:display-name="Strong Emphasis" style:family="text">
   <style:text-properties fo:font-weight="bold" style:font-weight-asian="bold" style:font-weight-complex="bold"/>
  </style:style>
  <style:style style:name="Underline_20_Emphasis" style:display-name="Underline Emphasis" style:family="text">
   <style:text-properties style:text-underline-style="solid" style:text-underline-width="auto" style:text-underline-color="font-color"/>
  </style:style>

  <text:list-style style:name="SKGB-Regeln">
   <text:list-level-style-number text:level="1" text:style-name="Strong_20_Emphasis" style:num-prefix="§ " style:num-suffix=" " style:num-format="1">
    <style:list-level-properties text:list-level-position-and-space-mode="label-alignment">
     <style:list-level-label-alignment text:label-followed-by="space"/>
    </style:list-level-properties>
   </text:list-level-style-number>
   <text:list-level-style-number text:level="2" style:num-prefix="(" style:num-suffix=")" style:num-format="1">
    <style:list-level-properties text:list-level-position-and-space-mode="label-alignment">
     <style:list-level-label-alignment text:label-followed-by="listtab" text:list-tab-stop-position="1.3cm" fo:text-indent="-0.8cm" fo:margin-left="1.3cm"/>
    </style:list-level-properties>
   </text:list-level-style-number>
   <text:list-level-style-number text:level="3" text:style-name="Numbering_20_Symbols" style:num-suffix=")" style:num-format="a">
    <style:list-level-properties text:list-level-position-and-space-mode="label-alignment">
     <style:list-level-label-alignment text:label-followed-by="listtab" text:list-tab-stop-position="2.3cm" fo:text-indent="-0.6cm" fo:margin-left="2.3cm"/>
    </style:list-level-properties>
   </text:list-level-style-number>
  </text:list-style>



  <!-- hide default styles we don't use: text -->
  <style:style style:name="Numbering_20_Symbols" style:display-name="Numbering Symbols" style:family="text" style:hidden="true"/>
  <style:style style:name="Caption_20_characters" style:display-name="Caption characters" style:family="text" style:hidden="true"/>
  <style:style style:name="Definition" style:family="text" style:hidden="true"/>
  <style:style style:name="Drop_20_Caps" style:display-name="Drop Caps" style:family="text" style:hidden="true"/>
  <!--style:style style:name="Emphasis" style:family="text" style:hidden="true"/-->
  <style:style style:name="Endnote_20_anchor" style:display-name="Endnote anchor" style:family="text" style:hidden="true"/>
  <style:style style:name="Example" style:family="text" style:hidden="true"/>
  <style:style style:name="Footnote_20_anchor" style:display-name="Footnote anchor" style:family="text" style:hidden="true"/>
  <style:style style:name="Index_20_Link" style:display-name="Index Link" style:family="text" style:hidden="true"/>
  <style:style style:name="Internet_20_link" style:display-name="Internet link" style:family="text" style:hidden="true"/>
  <style:style style:name="Line_20_numbering" style:display-name="Line numbering" style:family="text" style:hidden="true"/>
  <style:style style:name="Main_20_index_20_entry" style:display-name="Main index entry" style:family="text" style:hidden="true"/>
  <style:style style:name="Bullet_20_Symbols" style:display-name="Bullet Symbols" style:family="text" style:hidden="true"/>
  <style:style style:name="Endnote_20_Symbol" style:display-name="Endnote Symbol" style:family="text" style:hidden="true"/>
  <style:style style:name="Footnote_20_Symbol" style:display-name="Footnote Symbol" style:family="text" style:hidden="true"/>
  <style:style style:name="Page_20_Number" style:display-name="Page Number" style:family="text" style:hidden="true"/>
  <style:style style:name="Placeholder" style:family="text" style:hidden="true"/>
  <style:style style:name="Citation" style:family="text" style:hidden="true"/>
  <style:style style:name="Rubies" style:family="text" style:hidden="true"/>
  <style:style style:name="Source_20_Text" style:display-name="Source Text" style:family="text" style:hidden="true"/>
  <style:style style:name="Teletype" style:family="text" style:hidden="true"/>
  <style:style style:name="User_20_Entry" style:display-name="User Entry" style:family="text" style:hidden="true"/>
  <style:style style:name="Variable" style:family="text" style:hidden="true"/>
  <style:style style:name="Vertical_20_Numbering_20_Symbols" style:display-name="Vertical Numbering Symbols" style:family="text" style:hidden="true"/>
  <style:style style:name="Visited_20_Internet_20_Link" style:display-name="Visited Internet Link" style:family="text" style:hidden="true"/>
  <!-- hide default styles we don't use: paragraphs, top level -->
  <!--style:style style:name="Text_20_body" style:display-name="Text body" style:family="paragraph" style:hidden="true"/-->
  <style:style style:name="Heading" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="List" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Caption" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Index" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Header" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Quotations" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Preformatted_20_Text" style:display-name="Preformatted Text" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Sender" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Signature" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Table_20_Contents" style:display-name="Table Contents" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Marginalia" style:family="paragraph" style:hidden="true" style:parent-style-name="Text_20_body"/>
  <style:style style:name="List_20_Indent" style:display-name="List Indent" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="List_20_Heading" style:display-name="List Heading" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="List_20_Contents" style:display-name="List Contents" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Horizontal_20_Line" style:display-name="Horizontal Line" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Header_20_right" style:display-name="Header right" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Header_20_left" style:display-name="Header left" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Frame_20_contents" style:display-name="Frame contents" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Hanging_20_indent" style:display-name="Hanging indent" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Footnote" style:family="paragraph" style:hidden="true" style:parent-style-name="Standard"/>
  <style:style style:name="Footer_20_right" style:display-name="Footer right" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="First_20_line_20_indent" style:display-name="First line indent" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Footer" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Footer_20_left" style:display-name="Footer left" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Endnote" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Salutation" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Addressee" style:family="paragraph" style:hidden="true"/>
  <style:style style:name="Text_20_body_20_indent" style:display-name="Text body indent" style:family="paragraph" style:hidden="true"/>

 </office:styles>

 <office:automatic-styles>
  
  <style:style style:name="fr1" style:family="graphic" style:parent-style-name="SKGB-Entwurfsvermerk-Frame">
   <style:graphic-properties text:anchor-type="paragraph" svg:x="0cm" svg:y="0cm" style:vertical-pos="from-top" style:vertical-rel="page" style:horizontal-pos="from-left" style:horizontal-rel="page" fo:padding="0cm" fo:border="none" draw:textarea-vertical-align="middle"/>
  </style:style>
  
  <style:style style:name="gr1" style:family="graphic">
   <style:graphic-properties style:run-through="foreground" style:wrap="run-through" style:number-wrapped-paragraphs="no-limit" style:vertical-pos="from-top" style:vertical-rel="page" style:horizontal-pos="center" style:horizontal-rel="page" draw:wrap-influence-on-position="once-concurrent" style:flow-with-text="false"/>
  </style:style>
  <style:style style:name="gr2" style:family="graphic">
   <style:graphic-properties draw:stroke="none" draw:fill="solid" draw:fill-color="#ffffff" draw:shadow="hidden" style:run-through="foreground"/>
  </style:style>
  <style:style style:name="gr3" style:family="graphic">
   <style:graphic-properties draw:stroke="none" draw:fill="solid" draw:fill-color="#ff3333" draw:shadow="hidden" style:run-through="foreground"/>
  </style:style>
  <style:style style:name="gr4" style:family="graphic">
   <style:graphic-properties draw:stroke="none" draw:fill="solid" draw:fill-color="#000000" draw:shadow="hidden" style:run-through="foreground"/>
  </style:style>
  
  <style:page-layout style:name="regeln_pm1">
   <style:page-layout-properties fo:page-width="21cm" fo:page-height="29.7cm" style:num-format="1" style:print-orientation="portrait" fo:margin-top="2cm" fo:margin-bottom="1.8cm" fo:margin-left="2cm" fo:margin-right="2cm" style:writing-mode="lr-tb" style:footnote-max-height="0cm">
    <style:footnote-sep style:width="0.018cm" style:distance-before-sep="0.1cm" style:distance-after-sep="0.1cm" style:line-style="none" style:adjustment="left" style:rel-width="25%" style:color="#000000"/>
   </style:page-layout-properties>
  </style:page-layout>
  <style:page-layout style:name="regeln_pm2">
   <style:page-layout-properties fo:page-width="21cm" fo:page-height="29.7cm" style:num-format="1" style:print-orientation="portrait" fo:margin-top="1.5cm" fo:margin-bottom="1.8cm" fo:margin-left="2cm" fo:margin-right="2cm" style:writing-mode="lr-tb" style:footnote-max-height="0cm">
    <style:footnote-sep style:width="0.018cm" style:distance-before-sep="0.1cm" style:distance-after-sep="0.1cm" style:line-style="none" style:adjustment="left" style:rel-width="25%" style:color="#000000"/>
   </style:page-layout-properties>
   <style:header-style>
    <style:header-footer-properties fo:min-height="3.5cm" fo:margin-left="0cm" fo:margin-right="0cm" fo:margin-bottom=".9cm" style:shadow="none" fo:background-color="transparent" style:dynamic-spacing="false" draw:fill="none"/>
   </style:header-style>
  </style:page-layout>
 </office:automatic-styles>

 <office:master-styles>
  <style:master-page style:name="SKGB-Regeln-Seite" style:page-layout-name="regeln_pm1"/>
  <style:master-page style:name="SKGB-Regeln-Titelseite" style:page-layout-name="regeln_pm2" style:next-style-name="SKGB-Regeln-Seite">
   <style:header>
    <text:p text:style-name="SKGB-Regeln-Vereinsname">Segel- und Kanugemeinschaft Brucher Talsperre</text:p>
   </style:header>
  </style:master-page>
  <!-- hide default styles we don't use: pages -->
  <style:master-page style:name="Endnote" style:hidden="true"/>
  <style:master-page style:name="Envelope" style:hidden="true"/>
  <style:master-page style:name="First_20_Page" style:hidden="true" style:display-name="First Page"/>
  <style:master-page style:name="Footnote" style:hidden="true"/>
  <style:master-page style:name="HTML" style:hidden="true"/>
  <style:master-page style:name="Index" style:hidden="true"/>
  <style:master-page style:name="Landscape" style:hidden="true"/>
  <style:master-page style:name="Left_20_Page" style:hidden="true" style:display-name="Left Page"/>
  <style:master-page style:name="Right_20_Page" style:hidden="true" style:display-name="Right Page"/>
 </office:master-styles>




			<office:body>
				<office:text>
					<xsl:apply-templates/>
					<!--xsl:apply-templates select="descendant-or-self::regeln:regeln/*"/-->
				</office:text>
			</office:body>
		</office:document>
	</xsl:template>
	
	<xsl:template match="regeln:name">
		<xsl:choose>
			<xsl:when test="..//regeln:entwurf">
				<xsl:call-template name="entwurfsvermerk"/>
			</xsl:when>
		</xsl:choose>
		<!--h1>
		<p class="stand">
			<xsl:choose>
				<xsl:when test="..//regeln:stand/@stand">
					<xsl:call-template name="fassung-vom">
						<xsl:with-param name="stand" select="..//regeln:stand/@stand"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="..//regeln:stand">
					<xsl:call-template name="fassung-vom">
						<xsl:with-param name="stand" select="..//regeln:stand"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="..//@stand">
					<xsl:call-template name="fassung-vom">
						<xsl:with-param name="stand" select="..//@stand"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="fassung-vom"/>
				</xsl:otherwise>
			</xsl:choose>
		</p-->
		<!-- Stander hier auf 80 % skaliert -->
		<draw:g text:anchor-type="page" text:anchor-page-number="1" draw:z-index="0" draw:style-name="gr1">
			<draw:path draw:style-name="gr2" draw:text-style-name="P54" svg:width="2.721cm" svg:height="1.415cm" svg:x="9.69cm" svg:y="1.927cm" svg:viewBox="0 0 2722 1416" svg:d="M980 109c-381-192-622-71-622-71 0 0 56 265 33 389-52 286-119 388-360 608-7 27-28 95-31 123 395-39 698-30 1002 64 138 44 427 108 615 156 368 95 827 9 1105-232-439-178-845-400-1019-529-62-47-654-473-723-508z">
				<text:p/>
			</draw:path>
			<draw:path draw:style-name="gr3" draw:text-style-name="P55" svg:width="2.296cm" svg:height="1.375cm" svg:x="10.073cm" svg:y="1.944cm" svg:viewBox="0 0 2297 1376" svg:d="M1237 1342c-188-49-611-159-611-159l52-160c0 0 105 35 198-21 96-57 126-140 126-140 0 0 146 71 523 182 247 74 569 98 772 86-352 282-832 271-1060 212zM665 508c-104 41-159 150-159 150 0 0-125-80-238-101-173-31-268 9-268 9 0 0 46-161 39-280-6-120-37-246-37-246 0 0 204-125 585 67 48 25 371 251 371 251l-78 171c0 0-105-64-215-21z">
				<text:p/>
			</draw:path>
			<draw:path draw:style-name="gr4" draw:text-style-name="P56" svg:width="4.048cm" svg:height="2.448cm" svg:x="8.475cm" svg:y="1.5cm" svg:viewBox="0 0 4049 2449" svg:d="M1 2292c0 0-22 157 172 157 185 0 215-71 213-135-4-114-160-111-162-165-1-23 13-27 26-27 51 0 43 55 43 55h134c0 0 15-148-177-148-160 0-185 95-184 129 4 107 154 118 156 174 0 29-15 32-36 32-47 0-46-71-46-71zM531 2038l-114 402h143l54-192 65 192h144l-64-188 179-214h-178l-132 158 43-158zM1531 2260l-30 104h99c0 0 22 0 34-40 18-64-24-64-24-64zM1571 2118l-26 89h95c0 0 26 1 37-38 16-51-27-51-27-51zM1451 2038l-115 402h320c0 0 96 0 123-93 17-62-45-101-45-101 0 0 55-14 68-62 41-146-64-146-64-146zM1091 1644l-34 122c0 0-53-11-90-33-26-16-31-39 34-66 57-24 90-23 90-23zM1547 574l-215 760c0 0 42-31 112-141 64-98 124-218 124-405 1-157-21-214-21-214zM1496 209c-26-30-36-72-27-114 18-68 88-109 157-91 70 18 111 89 94 156-11 43-43 75-82 89-2 7-3 10-3 10l-45 162c0 0 92-36 190-36 150 0 353 38 598 220 50 37 532 381 578 415 51 38 236 146 290 173 605 311 601 295 803 358-52 38-366 319-883 319-187 0-429-52-692-117-412-101-570-151-930-151-136 0-295 26-295 26l-50 180c0 0 65 10 109 56 97 101 36 236-77 257 17-38 34-115-1-169-22-36-62-35-62-35 0 0-106 377-111 395-6 19-3 52 41 52 48 0 70-52 70-52l-56-14 20-74 200 6-57 210h-59l-4-58c0 0-44 64-183 64-119 0-127-130-118-166 4-16 115-405 115-405 0 0-246-75-215-183 41-148 313-160 313-160l370-1313c0 0 1-2 2-10zM2722 1717c-65-17-479-120-557-141-126-33-433-77-606-77-131 0-231 13-279 20 7-23 3-9 9-33 16-9 271-195 349-487 65-244 6-456 0-493 45-22 313-87 708 194 61 43 558 396 615 436 61 44 202 123 266 154 497 247 577 277 612 287-409 271-826 216-1117 140zM2351 906c-165 0-298 134-298 301 0 166 133 301 298 301 164 0 297-135 297-301 0-167-133-301-297-301zM2351 1421c-116 0-210-96-210-214s94-214 210-214 211 96 211 214-95 214-211 214zM2521 1275c0-9-3-8-52-9-43-91-112-127-127-177 20-28 40-10 39-27-1-8-11-10-38-8-35 1-41 2-53 27-7 12-54 104-61 119-12-2-49-9-64-7 3 25 25 80 52 94-4 12-12 3-16 24-5 24 1 28 16 34 12 6 25-2 32-19 9-27-3-26-2-38 7 0 247 0 255 0 17 0 19 0 19-13zM2379 1223c1-3 3-5 6-6l21-8c4-1 8 0 8 2l6 18c2 6-3 13-10 13h-35c-2 0-3-4-1-8zM2223 1328c-4-1-6-7-4-13 2-7 7-11 10-9 4 1 6 8 4 13-2 7-6 11-10 9z">
				<text:p/>
			</draw:path>
		</draw:g>
		<text:p text:style-name="SKGB-Regeln-Titel"><xsl:apply-templates/></text:p>
		<xsl:choose>
			<xsl:when test="..//regeln:stand/@stand">
				<xsl:call-template name="fassung-vom">
					<xsl:with-param name="stand" select="..//regeln:stand/@stand"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="..//regeln:stand">
				<xsl:call-template name="fassung-vom">
					<xsl:with-param name="stand" select="..//regeln:stand"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="..//@stand">
				<xsl:call-template name="fassung-vom">
					<xsl:with-param name="stand" select="..//@stand"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="fassung-vom"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name='fassung-vom'>
		<xsl:param name="stand"/>
		<xsl:if test="$stand">
			<text:p text:style-name="SKGB-Regeln-Stand">
				<xsl:text>in der Fassung vom </xsl:text>
				<xsl:value-of select="$stand"/>
			</text:p>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="regeln:satzung">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="regeln:ordnung">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="regeln:vorschrift">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="regeln:praeambel">
		<text:p text:style-name="SKGB-Regeln-Praeambel">
			<xsl:text>Präambel:</xsl:text>
			<text:line-break/>
			<xsl:apply-templates/>
		</text:p>
	</xsl:template>
	
	<xsl:template match="regeln:postambel">
		<text:p text:style-name="SKGB-Regeln-Praeambel">
			<xsl:apply-templates/>
		</text:p>
	</xsl:template>
	
	<xsl:template match='regeln:p'>
	</xsl:template>
	
	<xsl:template match='regeln:p[1]'>
		<text:list text:style-name="SKGB-Regeln">
			<xsl:call-template name="ins-del"/>
			<xsl:for-each select="following-sibling::*[local-name()='p']">
				<xsl:call-template name="ins-del"/>
			</xsl:for-each>
		</text:list>
	</xsl:template>
	
	<xsl:template match='regeln:p' mode="ins-del">
		<text:list-item>
		<text:p text:style-name="SKGB-Regeln-Paragraph"><xsl:apply-templates select="./regeln:titel" mode="apply-templates"/></text:p>
		<xsl:choose>
			<xsl:when test="regeln:abs">
				<xsl:variable name="absCount" select="count(./regeln:abs) - count(./regeln:abs/@gestrichenam)"/>
				<xsl:choose>
					<xsl:when test="$absCount = 1">
						<!-- paragraph mit 1 absatz MIT <abs> -->
	<!-- einstweilige loesung; dann nachbearbeiten, siehe regeln.pl
	-->
						<text:p text:style-name="SKGB-Regeln-Absatz-single"/>
						<xsl:apply-templates/>
					</xsl:when>
					<xsl:otherwise>
						<text:list>
							<xsl:apply-templates/>
						</text:list>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- paragraph mit 1 absatz OHNE <abs> -->
	<!-- einstweilige loesung; dann nachbearbeiten, zB:
perl -e '$_=join "",<>; s{<text:p text:style-name="SKGB-Regeln-Absatz-single"/>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Absatz-single">}g; print;'
	-->
				<text:p text:style-name="SKGB-Regeln-Absatz-single"/>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
		</text:list-item>
	</xsl:template>
	
	
	
	<xsl:template match='regeln:abs'>
		<xsl:choose>
			<xsl:when test="@gestrichenam">
				
			</xsl:when>
			<xsl:otherwise>
				<text:list-item>
					<xsl:call-template name="ins-del"/>
				</text:list-item>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match='regeln:abs' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match='regeln:lit/regeln:titel'>
		<em><xsl:value-of select="."/><xsl:text>:</xsl:text></em><br/>
	</xsl:template>
	
	<xsl:template match='regeln:nr/regeln:titel'>
		<strong><xsl:value-of select="."/></strong><br/>
		<!--text:p text:style-name="SKGB-Regeln-Absatz"><text:span text:style-name="Strong_20_Emphasis"><xsl:value-of select="."/></text:span><text:line-break/></text:p-->
	</xsl:template>
	
	<xsl:template match='regeln:abs/regeln:titel'>
		<text:p text:style-name="SKGB-Regeln-Absatz"><text:span text:style-name="Emphasis"><xsl:value-of select="."/><xsl:text>:</xsl:text></text:span><text:line-break/></text:p>
	</xsl:template>
	
	<xsl:template match='regeln:titel'>
	</xsl:template>
	
	<xsl:template match='regeln:titel' mode="apply-templates">
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:titel' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- BUG: ist mitten im absatz eine lit-liste eingefuegt, wird diese hiermit uebersprungen und erst am ende eingefuegt. was wir bräuchten: CSS-+-selektor -->
	<!-- http://stackoverflow.com/questions/19457502/xpath-to-select-only-direct-siblings-with-matching-attributes doesnt help -->
	<!-- einstweilige loesung: ein <text:p> je <regeln:s>, dann nachbearbeiten, zB:
perl -e '$_=join "",<>; s{</text:p>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{ }g; print;'
	-->
	<!-- spaeter evtl. so: <xsl:value-of select="."/> The xsl:value-of instruction automatically returns the string value of a node that is a concatenation of all text node descendants.	http://www.ibm.com/developerworks/library/x-xsltmistakes/ -->
	<!--
	<xsl:template match='regeln:s'>
	</xsl:template>
	<xsl:template match='regeln:s[1]'>
		<text:p text:style-name="SKGB-Regeln-Absatz">
			<xsl:call-template name="ins-del"/>
			<xsl:for-each select="following-sibling::*[local-name()='s']">
				<xsl:text> </xsl:text><xsl:call-template name="ins-del"/>
			</xsl:for-each>
		</text:p>
	</xsl:template>
	<xsl:template match='regeln:s' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	-->
	
	<xsl:template match='regeln:s'>
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:s' mode="ins-del">
		<text:p text:style-name="SKGB-Regeln-Absatz">
			<xsl:apply-templates/>
		</text:p>
	</xsl:template>
	
	<xsl:template match='regeln:t'><!-- text (meaning "text without any other meaning / simple span of text") / Teil-Satz -->
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:t' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match='regeln:steil'><!-- Satzteil; deprecated in favour of <t> -->
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:steil' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match='regeln:bereich'>
		<xsl:call-template name="ins-del"/>
	</xsl:template>
		
	<xsl:template match='regeln:bereich' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- BUG: es entstehen evtl. doppelte Leerzeichen -->
	<!-- einstweilige loesung: nachbearbeiten, zB:
perl -e '$_=join "",<>; s{ +}{ }g; print;'
	-->
	<xsl:template name='ins-del'>
		<xsl:choose>
			<xsl:when test="@eingefuegtam and @gestrichenam">
				
			</xsl:when>
			<xsl:when test="@gestrichenam">
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="ins-del"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match='regeln:lit[1]'>
		<text:list>
			<text:list-item>
				<xsl:call-template name="ins-del"/>
			</text:list-item>
			<xsl:for-each select="following-sibling::*[local-name()='lit']">
				<text:list-item>
					<xsl:call-template name="ins-del"/>
				</text:list-item>
			</xsl:for-each>
		</text:list>
	</xsl:template>
	
	<xsl:template match='regeln:lit'>
	</xsl:template>
	
	<!-- BUG: schlaegt fehl, wenn das lit noch irgendwas anderes enthaelt -->
	<!-- einstweilige loesung: nachbearbeiten, zB:
perl -e '$_=join "",<>; s{<text:p text:style-name="SKGB-Regeln-Buchstaben">\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Buchstaben">}g; s{</text:p>\s*</text:p>}{</text:p>}g; print;'
	-->
	<xsl:template match='regeln:lit' mode="ins-del">
		<text:p text:style-name="SKGB-Regeln-Buchstaben">
			<xsl:apply-templates/>
		</text:p>
	</xsl:template>
	
	<!-- BUG: geht's nach lit-Liste mit fliesstext weiter, soll kein vertikaler abstand entstehen -->
	<!-- einstweilige loesung: nachbearbeiten, zB:
perl -e '$_=join "",<>; s{</text:list>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{</text:list>\n<text:p text:style-name="SKGB-Regeln-Buchstaben">}g; print;'
	-->
	
	<!-- BUG: in 9 (1) satzung kapselt <s> eine lit-Liste - böse, aber prinzipiell ja nicht falsch. was es bedeutet: <s> muss, falls wir es weiterverwenden wollen, den "satz" als einzige semantik beinhalten und die listen/textabsatz-logik muss anders entstehen (was wohl so war, wie's mal gedacht war).
 -->
	<!-- einstweilige loesung: nachbearbeitend , zB:
perl -e '$_=join "",<>; s{<text:p([^>]*)>\s*([^<>]+)\s*<text:list>}{<text:p\1>\2</text:p><text:list>}g; s{</text:list>\s*</text:p>}{</text:list>}g; s{</text:list>\s*([^<>]+)\s*</text:p>}{</text:list><text:p text:style-name="SKGB-Regeln-Buchstaben">\1</text:p>}g; print;'
	-->
	
	<xsl:template match='regeln:abs/regeln:nr'>
	</xsl:template>

	<xsl:template match='regeln:abs/regeln:nr[1]'>
		<text:list>
			<text:list-item>
				<text:list>
					<text:list-item>
						<xsl:call-template name="ins-del"/>
					</text:list-item>
					<xsl:for-each select="following-sibling::*[local-name()='nr']">
						<text:list-item>
							<xsl:call-template name="ins-del"/>
						</text:list-item>
					</xsl:for-each>
				</text:list>
			</text:list-item>
		</text:list>
	</xsl:template>
	
	<!--xsl:template match='regeln:nr[1]'>
		<ol class="nr">
			<li value="1">
				<xsl:call-template name="ins-del"/>
			</li>
			<xsl:for-each select="following-sibling::*[local-name()='nr']">
			    <xsl:variable name="num">
			    	<xsl:value-of select="1 + count(preceding-sibling::regeln:nr) - count(preceding-sibling::regeln:nr/@gestrichenam)"/>
			    </xsl:variable>
				<li value="{$num}">
					<xsl:call-template name="ins-del"/>
				</li>
			</xsl:for-each>
		</ol>
	</xsl:template-->
	
	<!--xsl:template match='regeln:abs/regeln:nr'>
	</xsl:template-->
	
	<xsl:template match='regeln:abs/regeln:nr' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match='regeln:entwurf'>
	</xsl:template>
	
	<xsl:template name='entwurfsvermerk'>
		<draw:frame draw:style-name="fr1" draw:name="Entwurfsvermerk" text:anchor-type="page" text:anchor-page-number="1" svg:x="12.7cm" svg:y="1.6cm" svg:width="6.3cm" draw:z-index="1">
			<draw:text-box fo:min-height="1.1cm">
				<text:p text:style-name="SKGB-Regeln-Entwurfsvermerk">—ENTWURF—</text:p>
			</draw:text-box>
		</draw:frame>
	</xsl:template>
	
	<xsl:template match='regeln:aktuell'>
		<xsl:choose>
			<xsl:when test="attribute::den">
<!--
				<p class="up-to-date">
					Marienheide, den <xsl:value-of select="attribute::den"/><br/>
				</p>
				<address class="signature">
					Segel- und Kanugemeinschaft Brucher Talsperre<br/>
					<span class="signature">Arne Johannessen</span><br/>
					Geschäftsführer
				</address>
-->
				<text:p text:style-name="SKGB-Regeln-Ausfertigungsvermerk">Segel- und Kanugemeinschaft Brucher Talsperre<text:line-break/>Der Vorstand</text:p>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match='regeln:beitragsliste'>
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:beitragsliste' mode="ins-del">
		
			<xsl:apply-templates/>
		
	</xsl:template>
	
	<xsl:template match='regeln:beitrag | regeln:gebuehr'>
		<text:p text:style-name="SKGB-Regeln-Buchstaben">
			<xsl:apply-templates select="./regeln:t"/>
			<xsl:text>: </xsl:text>
			<xsl:apply-templates select="./regeln:dm | ./regeln:euro"/>
		</text:p>
	</xsl:template>
	
	<xsl:template match='regeln:dm | regeln:euro'>
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:dm' mode="ins-del">
		<xsl:apply-templates/>
		<xsl:text>,– DM</xsl:text>
	</xsl:template>
	
	<xsl:template match='regeln:euro' mode="ins-del">
		<xsl:apply-templates/>
		<xsl:text>,– €</xsl:text>
	</xsl:template>
	
	<xsl:template match="regeln:dm[not(*) and not(normalize-space())] | regeln:euro[not(*) and not(normalize-space())]" mode="ins-del">
		<!-- match empty element -->
		<xsl:choose>
			<xsl:when test="attribute::hinweis">
				<xsl:value-of select="@hinweis"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>–</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match='regeln:dump'>
		<!--text:p-->
			<xsl:apply-templates/>
		<!--/text:p-->
	</xsl:template>
	
</xsl:transform>


	<!--

aufhuebschen:
perl -e '$_=join "",<>; s{><text:list-item>}{>\n<text:list-item>}g; print;'

( xsltproc regeln2odf.xsl - | perl -e '$_=join "",<>; s{<text:p([^>]*)>\s*([^<>]+)\s*<text:list>}{<text:p\1>\2</text:p><text:list>}g; s{</text:list>\s*</text:p>}{</text:list>}g; s{</text:list>\s*([^<>]+)\s*</text:p>}{</text:list><text:p text:style-name="SKGB-Regeln-Buchstaben">\1</text:p>}g; s{<text:p text:style-name="SKGB-Regeln-Absatz-single"/>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Absatz-single">}g; s{</text:p>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{ }g; s{ +}{ }g; s{<text:p text:style-name="SKGB-Regeln-Buchstaben">\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Buchstaben">}g; s{</text:p>\s*</text:p>}{</text:p>}g; s{><text:list-item>}{>\n<text:list-item>}g; s{</text:list>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{</text:list>\n<text:p text:style-name="SKGB-Regeln-Buchstaben">}g; print;') < Satzung\ 2015.xml > Satzung\ 2015.fodt ; open Satzung\ 2015.fodt

( xsltproc regeln2odf.xsl - | perl -e '$_=join "",<>; s{<text:p([^>]*)>\s*([^<>]+)\s*<text:list>}{<text:p\1>\2</text:p><text:list>}g; s{</text:list>\s*</text:p>}{</text:list>}g; s{</text:list>\s*([^<>]+)\s*</text:p>}{</text:list><text:p text:style-name="SKGB-Regeln-Buchstaben">\1</text:p>}g; s{<text:p text:style-name="SKGB-Regeln-Absatz-single"/>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Absatz-single">}g; s{</text:p>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{ }g; s{ +}{ }g; s{<text:p text:style-name="SKGB-Regeln-Buchstaben">\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Buchstaben">}g; s{</text:p>\s*</text:p>}{</text:p>}g; s{><text:list-item>}{>\n<text:list-item>}g; s{</text:list>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{</text:list>\n<text:p text:style-name="SKGB-Regeln-Buchstaben">}g; print;') < DSE.e.xml > DSE.e.fodt ; open DSE.e.fodt 

	-->
