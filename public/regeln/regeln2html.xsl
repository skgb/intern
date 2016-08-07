<?xml version="1.0" encoding="utf-8" standalone="yes"?>

<!--

XSLT conversion specification for 'SKGB-Regeln' to HTML
(c) 2005-2016 Segel- und Kanugemeinschaft Brucher Talsperre e. V. SKGB
Proprietary/Confidential. All Rights Reserved.

$Id: regeln2html.xsl 842 2016-09-06 20:19:27Z aj $

-->


<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:regeln="http://www.skgb.de/2005/regeln" xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml" exclude-result-prefixes="regeln html">
	
	<xsl:template name='check-version'>
		<xsl:variable name="version" select="number(0.81)"/><!-- SKGB-Regeln format version -->
		
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
	
	
	<xsl:namespace-alias stylesheet-prefix="html" result-prefix="#default"/>

	<!-- Need to instruct the XSLT processor to use HTML output rules.
		 See http://www.w3.org/TR/xslt#output for more details
	-->
	<xsl:output method="xml" media-type="application/xhtml+xml" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" omit-xml-declaration="no" standalone="no" indent="no"/>
	<!-- indent or cdata-section-elements ? -->
	<!-- doctype: check out if counting LIs are in fact supported by Strict; check out XHTML5 -->
	
	<xsl:template match="html:*">
		<!--xsl:copy><xsl:apply-templates/></xsl:copy-->
		<!--xsl:element name="{local-name()}" use-attribute-sets="html:href"><xsl:apply-templates/></xsl:element-->
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="/">
		<xsl:call-template name="check-version"/>
		<xsl:processing-instruction name="xml-stylesheet">href="#style" type="text/css"</xsl:processing-instruction>
		<html xml:lang="de">
			<head>
				<title>
					<xsl:value-of select="//regeln:name"/>
					<xsl:text> – SKGB</xsl:text>
					<xsl:if test="//regeln:entwurf">
						<xsl:text> – Entwurf </xsl:text>
						<xsl:value-of select="//regeln:entwurf/@revision"/>
					</xsl:if>
				</title>
				<style type="text/css" id="style">
					<xsl:text>
html {
	margin: 8px;
}
body {
	margin: 0;
}
pre {
	width: 100%;
	white-space: pre-line;
	font-size: 92%;
	font-family: monospace;
	font-family: "Courier", "CMU Typewriter Text", "Free Mono", "Prestige Elite Std", "Courier New";
}
del, del *, ins del, ins del *, del ins, del ins *, li.gestrichen {
	background: #fbb;
	-webkit-text-decoration-color: #a00;
	text-decoration-color: #a00;
}
del dt {
	text-decoration: line-through; /* for some reason this value is not inherited */
}
ins, ins * {
	-webkit-text-decoration-color: #0a0;
	text-decoration-color: #0a0;
}
h1 {
	font-size: 1.5em;
	font-weight: normal;
	text-align: center;
	background-image: url(Stander.svg);
	background-repeat: no-repeat;
	background-position: center top;
	padding-top: 107px;
	margin-bottom: 0;
}
.rules {
	position: relative;
}
.rules+.rules {
	border-top: .05cm dotted black;
	margin-top: 2.5em;
	padding-top: .5em;
}
.draftnotice>strong {
	font-weight: normal;
	text-transform: uppercase;
}
.draftnotice>strong:before, .draftnotice>strong:after {
	content: '—';
}
.draftnotice {
	text-align: right;
	font-size: 2.4em;
	margin: 0;
	position: absolute;
	top: .6em;
	right: .6em;
	-webkit-transform: rotate(15deg) translateY(.6em);
	-moz-transform: rotate(15deg) translateY(.6em);
	-o-transform: rotate(15deg) translateY(.6em);
}
p.stand {
	text-align: center;
	margin: .5em 0 2em;
}
h2>.p-number {
	padding-right: 1ex;
}
h2 {
	font-size: 1em;
	margin: 1.5em 0 .5em;
}
.preamble, .postamble, .up-to-date, .signature {
	font-style: italic;
}
.preamble:before {
	content: 'Präambel: ';
}
p.up-to-date {
	margin-bottom: 0;
}
ol, li {
	margin-top: 0;
	margin-bottom: 0;
}
ol {
	padding-left: 3em;
}
.bylaws>ol>li, .rules>ol>li, .directive>ol>li, .bylaws>*>ol>li, .rules>*>ol>li, .directive>*>ol>li, dl {
	margin: .5em 0;
}
ol.alleine {
	padding-left: 0;
}
ol.alleine>li {
	display: block;
}
dt {
	float: left;
	clear: left;
}
dl::after {
	display: block;
	color: transparent;
	height: 0;
	content: '.'; 
	clear: left;
}
dt::after {
	content: ' '; 
	padding-right: 1ex;
}
dd>ins, dd>del {
	margin-right: .5ex;
}
dd {
	font-weight: bold;
}
del dd, dd del {
	font-weight: normal;
}
address.signature span.signature {
	padding-top: 43px;
	display: inline-block;
	background-repeat: no-repeat;
	background-position: 0 5px;
	background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFEAAAAjCAMAAADbuxbOAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAF1QTFRFVVVVqqqqODg4HBwc4uLixsbGjY2NcXFxQEBAgICAv7+/FRUVlZWVKioqampqKysr6enp6urq1dXV1NTUz8/Pf39/kJCQEBAQYGBglJSUsLCwICAgPz8/AAAA////M3leOwAAAjdJREFUeNqsloeOpDAMhl3S6EzZ3WvO+z/mpQCB4UbHReeRRihRPlx+O4A/GYB/Yyr8/mrn0zi8I85ifQ1Rde+IregqopdtjeEQZUO+ioirj0hW+ECEOqJdfFQhayTtbmfQVcSbfOU1nO4e5XPnvPNVRMW5orO1h5x6T00d0XLOY0t4pKBgHZE4K7w18V+XfZBHFRHZNBIf+hS7LT6y+CoisIZ0tDGp3htRC1QRFRs/ZiImSfYljaaK2E+t/5aIP/rUd891xx2keZ3IGM8Wl7e+U7F9KhRuKTRyVwZC6UJN4ZHUPxOTcHY+gilphIi9TFQD6CQdTMTVFc1YiIGmr08z07EEZh5Xw+ajKfErCc0JfyTq46uWqEfNIpL7rxBhF6UR6fmljho/iOPBYKxPeWwhMqcGv7pl5T6Jc5vEG5FpxPb+vPl722LTOFnMOTdO0j1PlQH5HqLDAE6jWxkkoa4IW2+I1Rg+donu7AtRrVIJB8PcmWM8Jmi8jHFHQCuLAF9GkfoVXwEz+FMZQKKfwkgxjcyrk2rIDK3eyFIhonmAX+9gpi167RHQGxtZhpe5qEguduEClE2FbkFQbpFQZPoI/oqMF4lLKOV2XxUOsukmGpn5GtF1tyiNqVxLjaQRhs26dGs/22s3QiLa6BF2vP90sHlH+xqDMAJCaYdd+R55WhOoOmK48YOkD5cSR4dnIl9JDN35Eh7ERPRgq4nnL584xEbQ/4/oY1OMlUH7t9+KP7GS+FuAAQChKCT0ocDhGwAAAABJRU5ErkJggg==);
}
@media print {
	body {
		font-size: 11pt !important;
	}
	pre {
		font-size: 9pt !important;
	}
	h2 {
		page-break-after: avoid;
	}
	ol, li:first-child {
		page-break-before: avoid;
	}
}
					</xsl:text>
				</style>
				<link rel="alternate stylesheet" title="Änderungen verbergen" type="text/css" href="data:text/css,ins%2Cins%20*%7Btext-decoration%3Anone%7Ddel%2Cdel%20*%2C.gestrichen%7Bdisplay%3Anone%7D"/>
				<link rel="stylesheet" title="Änderungen zeigen" type="text/css" href="data:text/css,ins%2Cins%20*%7Bbackground%3A%23bfb%7Dspan.geaendert%7Bbackground%3A%23ffa%7D"/>
			</head>
			<body>
				<xsl:apply-templates/>
				<!--xsl:apply-templates select="descendant-or-self::regeln:regeln/*"/-->
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="regeln:name">
		<h1>
			<xsl:apply-templates/>
		</h1>
		<xsl:choose>
			<xsl:when test="..//regeln:entwurf">
				<xsl:call-template name="entwurfsvermerk"/>
			</xsl:when>
		</xsl:choose>
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
		</p>
	</xsl:template>
	
	<xsl:template name='fassung-vom'>
		<xsl:param name="stand"/>
		<xsl:if test="$stand">
			<xsl:text>in der Fassung vom </xsl:text>
			<xsl:value-of select="$stand"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="regeln:satzung">
		<div class="bylaws">
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	
	<xsl:template match="regeln:ordnung">
		<div class="rules">
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	
	<xsl:template match="regeln:vorschrift">
		<div class="directive">
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	
	<xsl:template match="regeln:praeambel">
		<p class="preamble">
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match="regeln:postambel">
		<p class="postamble">
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match='regeln:p'>
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:p' mode="ins-del">
		<xsl:variable name="num" select="1 + count(preceding-sibling::regeln:p) - count(preceding-sibling::regeln:p/@gestrichenam)"/>
		<h2 class="p-{$num}"><span class="p-number">§ <xsl:value-of select="$num"/></span> <xsl:apply-templates select="./regeln:titel" mode="apply-templates"/></h2>
		<xsl:choose>
			<xsl:when test="regeln:abs">
				<xsl:variable name="absCount" select="count(./regeln:abs) - count(./regeln:abs/@gestrichenam)"/>
				<xsl:choose>
					<xsl:when test="$absCount = 1">
						<ol class="alleine">
							<xsl:apply-templates/>
						</ol>
					</xsl:when>
					<xsl:otherwise>
						<ol>
							<xsl:apply-templates/>
						</ol>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<div>
					<xsl:apply-templates/>
				</div>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match='regeln:abs'>
		<xsl:variable name="num" select="1 + count(preceding-sibling::regeln:abs) - count(preceding-sibling::regeln:abs/@gestrichenam)"/>
		<xsl:choose>
			<xsl:when test="@gestrichenam">
				<li value="{$num}" class="abs-{$num} gestrichen">
					<xsl:call-template name="ins-del"/>
				</li>
			</xsl:when>
			<xsl:otherwise>
				<li value="{$num}" class="abs-{$num}">
					<xsl:call-template name="ins-del"/>
				</li>
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
	</xsl:template>
	
	<xsl:template match='regeln:abs/regeln:titel'>
		<em><xsl:value-of select="."/><xsl:text>:</xsl:text></em><br/>
	</xsl:template>
	
	<xsl:template match='regeln:titel'>
	</xsl:template>
	
	<xsl:template match='regeln:titel' mode="apply-templates">
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:titel' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match='regeln:s'>
		<xsl:call-template name="ins-del"/>
	</xsl:template>
		
	<xsl:template match='regeln:s' mode="ins-del">
		<xsl:apply-templates/>
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

	<xsl:template name='ins-del'>
		<xsl:variable name="eingefuegt">
			<xsl:if test="@eingefuegtam and @eingefuegttop">
				<xsl:text> (TOP </xsl:text>
				<xsl:value-of select="@eingefuegttop"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="gestrichen">
			<xsl:if test="@gestrichenam and @gestrichentop">
				<xsl:text> (TOP </xsl:text>
				<xsl:value-of select="@gestrichentop"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="@eingefuegtam and @gestrichenam">
				<del datetime="{@gestrichenam}" title="eingefügt {@eingefuegtam}{$eingefuegt} und gestrichen {@gestrichenam}{$gestrichen}"><ins datetime="{@eingefuegtam}" title="eingefügt {@eingefuegtam}{$eingefuegt} und gestrichen {@gestrichenam}{$gestrichen}">
					<xsl:apply-templates select="." mode="ins-del"/>
				</ins></del>
			</xsl:when>
			<xsl:when test="@gestrichenam">
				<del datetime="{@gestrichenam}" title="gestrichen {@gestrichenam}{$gestrichen}">
					<xsl:apply-templates select="." mode="ins-del"/>
				</del>
			</xsl:when>
			<xsl:when test="@eingefuegtam">
				<ins datetime="{@eingefuegtam}" title="eingefügt {@eingefuegtam}{$eingefuegt}">
					<xsl:apply-templates select="." mode="ins-del"/>
				</ins>
			</xsl:when>
			<xsl:when test="@nachgefuehrtam">
				<span class="geaendert" title="nachgeführt {@nachgefuehrtam}">
					<xsl:apply-templates select="." mode="ins-del"/>
				</span>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="ins-del"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match='regeln:lit[1]'>
		<ol class="lit" type="a">
			<li value="1">
				<xsl:call-template name="ins-del"/>
			</li>
			<xsl:for-each select="following-sibling::*[local-name()='lit']">
			    <xsl:variable name="num">
			    	<xsl:value-of select="1 + count(preceding-sibling::regeln:lit) - count(preceding-sibling::regeln:lit/@gestrichenam)"/>
			    </xsl:variable>
				<li value="{$num}">
					<xsl:call-template name="ins-del"/>
				</li>
			</xsl:for-each>
		</ol>
	</xsl:template>
	
	<xsl:template match='regeln:lit'>
	</xsl:template>
	
	<xsl:template match='regeln:lit' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match='regeln:nr[1]'>
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
	</xsl:template>
	
	<xsl:template match='regeln:nr'>
	</xsl:template>
	
	<xsl:template match='regeln:nr' mode="ins-del">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match='regeln:entwurf'>
	</xsl:template>
	
	<xsl:template name='entwurfsvermerk'>
		<p class="draftnotice">
			<strong>Entwurf</strong>
		</p>
	</xsl:template>
	
	<xsl:template match='regeln:aktuell'>
		<xsl:choose>
			<xsl:when test="attribute::den">
				<p class="up-to-date">
					Marienheide, den <xsl:value-of select="attribute::den"/><br/>
				</p>
				<address class="signature">
					Segel- und Kanugemeinschaft Brucher Talsperre<br/>
					Der Vorstand
					<!--
					<span class="signature">Arne Johannessen</span><br/>
					Geschäftsführer
					-->
				</address>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match='regeln:beitragsliste'>
		<xsl:call-template name="ins-del"/>
	</xsl:template>
	
	<xsl:template match='regeln:beitragsliste' mode="ins-del">
		<dl>
			<xsl:apply-templates/>
		</dl>
	</xsl:template>
	
	<!-- <beitrag>/<gebuehr> unterstützen nicht ins/del ! -> simulieren durch geschachtelte <t>s -->
	<xsl:template match='regeln:beitrag | regeln:gebuehr'>
		<dt>
			<!--xsl:value-of select="normalize-space(./text())"/-->
			<xsl:apply-templates select="./regeln:t"/>
			<xsl:text>:</xsl:text>
		</dt>
		<dd>
			<xsl:apply-templates select="./regeln:dm | ./regeln:euro"/>
		</dd>
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
		<pre>
			<xsl:apply-templates/>
		</pre>
	</xsl:template>
	
</xsl:transform>
