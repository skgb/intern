#!/usr/bin/env perl
use Mojolicious::Lite;
use utf8;

use Mojo::Util qw(b64_decode);

plugin 'DefaultHelpers';

get '' => sub {
	my $c = shift;
	
	my $start = $c->param('start');
	my $liste = b64_decode $c->param('liste');
	
	my @liste = ();
	foreach my $date (split m/\n/, $liste) {
		my @date = split m/\t/, $date;
		push @liste, \@date;
	}
	
	my @months = qw(Januar Februar März April Mai Juni Juli August September Oktober November Dezember);
	my (undef, undef, undef, $Monatstag, $Monat, $Jahr, undef, undef, undef) = localtime;
	my $stand = sprintf("%2d. %s %4d", $Monatstag, $months[$Monat], $Jahr + 1900);
	
	$c->res->headers->content_disposition('attachment; filename=stegdienst.fodt;');
	$c->render(
		template => 'stegdienst',
		format => 'xml',
		start => $start,
		liste => \@liste,
		stand => $stand,
		export => "\n$start\n$liste",
	);
};

app->start;
__DATA__

@@ stegdienst.xml.ep
<?xml version="1.0" encoding="UTF-8"?>

<office:document xml:lang="de" office:version="1.2" office:mimetype="application/vnd.oasis.opendocument.text" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0">
 <office:meta><meta:generator>SKGB-intern/1.3</meta:generator></office:meta>
 
  <office:font-face-decls>
  <style:font-face style:name="FreeSerif" svg:font-family="FreeSerif" style:font-adornments="Regular" style:font-family-generic="roman" style:font-pitch="variable"/>
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
  
  <style:style style:name="SKGB-Titel" style:family="paragraph" style:parent-style-name="Standard">
   <style:paragraph-properties fo:text-align="center" fo:margin-bottom="0.5cm"/>
   <style:text-properties fo:font-size="15pt"/>
  </style:style>



  <style:style style:name="Emphasis" style:family="text">
   <style:text-properties fo:font-style="italic"/>
  </style:style>
  <style:style style:name="Strong_20_Emphasis" style:display-name="Strong Emphasis" style:family="text">
   <style:text-properties fo:font-weight="bold" style:font-weight-asian="bold" style:font-weight-complex="bold"/>
  </style:style>
  <style:style style:name="Underline_20_Emphasis" style:display-name="Underline Emphasis" style:family="text">
   <style:text-properties style:text-underline-style="solid" style:text-underline-width="auto" style:text-underline-color="font-color"/>
  </style:style>


  <style:style style:name="Table_20_Heading" style:display-name="Table Heading" style:family="paragraph">
   <style:paragraph-properties fo:text-align="center" style:justify-single-word="false"/>
  </style:style>
  <style:style style:name="Stegdienst-Datum" style:family="paragraph" style:parent-style-name="Standard">
   <style:paragraph-properties fo:text-align="center"/>
  </style:style>
  <style:style style:name="Text_20_body" style:display-name="Text body" style:family="paragraph" style:parent-style-name="Standard" style:class="text">
   <style:paragraph-properties fo:margin-top="0.2cm" fo:margin-bottom="0cm" />
  </style:style>
  <style:style style:name="Date-Signature" style:family="paragraph" style:parent-style-name="Text_20_body" style:class="text">
   <style:paragraph-properties fo:margin-top="0.5cm" fo:margin-bottom="0cm" />
   <style:text-properties fo:font-size="10pt"/>
  </style:style>

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
  
  <style:style style:name="P55" style:family="paragraph" style:parent-style-name="SKGB-Titel">
   <style:paragraph-properties style:page-number="auto"/>
  </style:style>

  <style:style style:name="Table1" style:family="table">
   <style:table-properties style:width="16cm" table:align="margins" style:shadow="none"/>
  </style:style>
  <style:style style:name="Table1.A" style:family="table-column">
   <style:table-column-properties style:column-width="2.5cm"/>
  </style:style>
  <style:style style:name="Table1.B" style:family="table-column">
   <style:table-column-properties style:column-width="4.7cm" style:use-optimal-column-width="true"/>
  </style:style>
  <style:style style:name="Table1.C" style:family="table-column">
   <style:table-column-properties style:column-width="4.5cm" style:use-optimal-column-width="true"/>
  </style:style>
  <style:style style:name="Table1.D" style:family="table-column">
   <style:table-column-properties style:column-width="4.3cm"/>
  </style:style>
  <style:style style:name="Table1.A1" style:family="table-cell">
   <style:table-cell-properties fo:padding="0.02cm" fo:border-left="none" fo:border-right="none" fo:border-top="none" fo:border-bottom="0.2mm solid #000000"/>
  </style:style>
  <style:style style:name="Table1.D1" style:family="table-cell">
   <style:table-cell-properties fo:padding-left="0.47cm" fo:padding-right="0.02cm" fo:padding-top="0.02cm" fo:padding-bottom="0.02cm" fo:border="none"/>
  </style:style>
  <style:style style:name="Table1.A2" style:family="table-cell" style:data-style-name="N84">
   <style:table-cell-properties fo:padding="0.02cm" fo:border-left="0.2mm solid #000000" fo:border-right="none" fo:border-top="none" fo:border-bottom="0.2mm solid #000000"/>
  </style:style>
  <style:style style:name="Table1.B2" style:family="table-cell">
   <style:table-cell-properties fo:padding-left="0.22cm" fo:padding-right="0.02cm" fo:padding-top="0.02cm" fo:padding-bottom="0.02cm" fo:border-left="0.2mm solid #000000" fo:border-right="none" fo:border-top="none" fo:border-bottom="0.2mm solid #000000"/>
  </style:style>
  <style:style style:name="Table1.C2" style:family="table-cell">
   <style:table-cell-properties fo:padding="0.02cm" fo:border-left="none" fo:border-right="0.2mm solid #000000" fo:border-top="none" fo:border-bottom="0.2mm solid #000000"/>
  </style:style>
  
  
  <style:style style:name="P5" style:family="paragraph" style:parent-style-name="Text_20_body">
   <style:paragraph-properties fo:margin-right="0.8cm"/>
  </style:style>
  
  
  
  
  <style:style style:name="gr1" style:family="graphic">
   <style:graphic-properties style:protect="position size" style:run-through="foreground" style:wrap="run-through" style:number-wrapped-paragraphs="no-limit" style:vertical-pos="from-top" style:vertical-rel="page" style:horizontal-pos="from-left" style:horizontal-rel="page" draw:wrap-influence-on-position="once-concurrent" style:flow-with-text="false"/>
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
  
  <style:page-layout style:name="pm1">
   <style:page-layout-properties fo:page-width="21.001cm" fo:page-height="29.7cm" style:num-format="1" style:print-orientation="portrait" fo:margin-top="2cm" fo:margin-bottom="0.7cm" fo:margin-left="3cm" fo:margin-right="2cm" style:writing-mode="lr-tb" style:footnote-max-height="0cm">
    <style:footnote-sep style:width="0.018cm" style:distance-before-sep="0.101cm" style:distance-after-sep="0.101cm" style:line-style="solid" style:adjustment="left" style:rel-width="25%" style:color="#000000"/>
   </style:page-layout-properties>
   <style:header-style>
    <style:header-footer-properties fo:min-height="2.7cm" fo:margin-left="0cm" fo:margin-right="0cm" fo:margin-bottom="0.7cm" fo:background-color="transparent" style:dynamic-spacing="false" draw:fill="none"/>
   </style:header-style>
   <style:footer-style/>
  </style:page-layout>
  
  <number:date-style style:name="N84">
   <number:year number:style="long"/>
   <number:text>-</number:text>
   <number:month number:style="long"/>
   <number:text>-</number:text>
   <number:day number:style="long"/>
  </number:date-style>
 </office:automatic-styles>

 <office:master-styles>
  <style:master-page style:name="Standard" style:page-layout-name="pm1">
   <style:header>
    <text:p text:style-name="Header"/>
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
   <text:sequence-decls>
    <text:sequence-decl text:display-outline-level="0" text:name="Illustration"/>
    <text:sequence-decl text:display-outline-level="0" text:name="Table"/>
    <text:sequence-decl text:display-outline-level="0" text:name="Text"/>
    <text:sequence-decl text:display-outline-level="0" text:name="Drawing"/>
   </text:sequence-decls>
   <draw:g text:anchor-type="page" text:anchor-page-number="1" draw:z-index="0" draw:style-name="gr1">
    <draw:path draw:style-name="gr2" draw:text-style-name="P61" svg:width="3.4cm" svg:height="1.768cm" svg:x="16.549cm" svg:y="1.485cm" svg:viewBox="0 0 3401 1769" svg:d="M1224 136c-476-240-777-89-777-89 0 0 70 332 42 487-65 357-149 485-450 760-9 34-35 118-39 153 493-48 872-37 1252 81 172 54 534 134 769 194 460 119 1033 11 1380-289-548-223-1056-500-1273-662-77-58-817-591-904-635z">
     <text:p/>
    </draw:path>
    <draw:path draw:style-name="gr3" draw:text-style-name="P62" svg:width="2.869cm" svg:height="1.719cm" svg:x="17.027cm" svg:y="1.508cm" svg:viewBox="0 0 2870 1720" svg:d="M1546 1677c-235-61-764-198-764-198l65-200c0 0 131 43 247-26 120-72 158-175 158-175 0 0 183 88 654 227 308 92 710 123 964 108-439 352-1039 338-1324 264zM831 635c-130 51-199 188-199 188 0 0-156-100-297-127-216-39-335 12-335 12 0 0 57-202 49-351s-46-307-46-307c0 0 254-156 730 84 60 31 464 313 464 313l-98 214c0 0-130-80-268-26z">
     <text:p/>
    </draw:path>
    <draw:path draw:style-name="gr4" draw:text-style-name="P63" svg:width="5.059cm" svg:height="3.06cm" svg:x="15.03cm" svg:y="0.951cm" svg:viewBox="0 0 5060 3061" svg:d="M1 2865c0 0-27 196 215 196 232 0 269-89 266-169-4-142-200-139-202-206-1-29 16-34 32-34 64 0 54 69 54 69h168c0 0 18-185-222-185-200 0-231 118-229 161 4 134 192 148 194 218 1 36-18 40-44 40-59 0-58-89-58-89zM664 2547l-143 503h179l67-241 81 241h181l-81-236 224-267h-222l-165 197 54-197zM1913 2824l-37 130h123c0 0 28 0 43-50 22-80-30-80-30-80zM1963 2647l-32 111h119c0 0 32 1 45-47 20-64-33-64-33-64zM1813 2547l-143 503h400c0 0 119 0 153-117 21-77-56-126-56-126 0 0 68-17 85-77 51-183-80-183-80-183zM1364 2055l-43 152c0 0-66-14-113-41-32-20-38-49 43-83 71-30 113-28 113-28zM1933 717l-268 950c0 0 52-38 140-176 80-123 154-273 155-506 1-196-27-268-27-268zM1870 261c-33-38-46-90-34-142 22-85 110-136 196-114 87 23 138 111 117 195-14 54-53 94-102 111-3 9-4 13-4 13l-56 202c0 0 115-45 237-45 188 0 441 48 747 275 63 46 665 476 723 519 63 47 295 182 362 216 756 388 751 369 1004 447-66 48-458 399-1104 399-233 0-536-65-865-146-514-127-712-189-1162-189-169 0-368 32-368 32l-63 225c0 0 82 13 137 71 121 126 45 294-97 321 22-48 43-144-1-212-28-45-78-43-78-43 0 0-132 471-138 494-7 23-4 65 51 65 60 0 87-66 87-66l-69-17 24-92 250 7-71 263h-73l-5-73c0 0-56 80-229 80-149 0-159-162-147-208 5-19 143-506 143-506 0 0-307-94-269-229 52-185 391-200 391-200l463-1640c0 0 1-3 3-13zM3402 2146c-82-22-599-150-697-176-157-42-541-97-757-97-163 0-288 17-348 25 8-29 3-11 11-41 20-11 339-244 436-609 81-304 7-570 0-616 56-27 391-108 885 243 76 54 697 495 768 545 76 55 252 153 333 192 621 309 720 346 764 359-511 338-1032 270-1395 175zM2938 1132c-206 0-372 168-372 376s166 377 372 377c205 0 371-169 371-377s-166-376-371-376zM2938 1776c-145 0-263-120-263-267 0-148 118-268 263-268s264 120 264 268c0 147-119 267-264 267zM3150 1594c0-12-3-10-65-12-53-114-140-159-159-221 25-35 51-12 49-34-1-10-14-12-47-10-44 2-52 3-67 34-8 15-67 130-76 149-15-3-61-12-79-9 3 31 31 100 64 117-4 15-14 4-19 31-7 29 1 35 19 42 15 7 32-3 40-24 11-34-4-32-2-47 9 0 308 0 319 0 21 0 23 0 23-16zM2973 1528c1-3 4-6 7-7l27-10c5-1 9 0 10 3l7 22c2 7-4 16-13 16h-43c-3 0-4-5-2-10zM2778 1660c-5-2-7-9-5-17 3-8 9-13 13-11 5 2 7 10 5 17-3 8-8 13-13 11z">
     <text:p/>
    </draw:path>
   </draw:g>
   <draw:path text:anchor-type="page" text:anchor-page-number="1" draw:z-index="1" draw:style-name="gr4" draw:text-style-name="P64" svg:width="12.6cm" svg:height="1.903cm" svg:x="2cm" svg:y="2.101cm" svg:viewBox="0 0 12601 1904" svg:d="M12601 1904h-12601v-80h12601zM49 971v403h77v-37h1c8 16 21 27 38 34s36 10 58 10c14 0 29-3 43-9s27-15 39-27c11-13 21-29 28-48 7-20 10-43 10-69 0-27-3-50-10-69-7-20-17-36-28-48-12-13-25-22-39-28s-29-9-43-9c-18 0-36 4-53 11-16 6-30 18-39 33h-1v-147zM263 1228c0 12-1 24-4 35-2 12-6 22-12 30-6 9-13 16-21 21-9 5-19 7-31 7s-22-2-31-7c-8-5-15-12-21-21-6-8-10-18-12-30-3-11-4-23-4-35s1-24 4-35c2-12 6-22 12-30 6-9 13-16 21-21 9-5 19-7 31-7s22 2 31 7c8 5 15 12 21 21 6 8 10 18 12 30 3 11 4 23 4 35zM381 1082v292h80v-132c0-13 1-25 4-36 2-12 7-22 13-30s14-15 25-20c10-5 22-7 37-7 5 0 10 0 15 0 5 1 10 2 14 2v-74c-7-2-13-3-18-3-10 0-20 2-29 5-10 3-18 7-27 12-8 6-15 12-22 20-6 8-11 16-15 25h-1v-54zM861 1374v-292h-81v153c0 30-5 51-14 64-10 13-26 20-48 20-19 0-32-6-40-18-7-12-11-30-11-54v-165h-80v180c0 18 1 34 5 49 3 15 8 27 16 38 8 10 19 18 33 24 13 5 31 8 52 8 17 0 34-3 50-11s29-20 40-37h1v41zM1107 1185h78c-1-19-6-35-13-49-8-14-19-25-31-35-13-9-27-16-43-20-16-5-33-7-50-7-24 0-45 4-63 12-19 8-34 19-47 33s-23 31-29 50c-7 20-10 41-10 63s3 42 11 60c7 19 17 34 30 48 12 13 28 23 46 30 18 8 38 11 60 11 39 0 71-10 96-30 24-21 40-50 45-89h-78c-2 18-9 33-19 43-10 11-25 16-44 16-13 0-23-2-32-8s-15-13-21-22c-5-9-8-18-11-29-2-11-3-22-3-33s1-22 3-33c3-11 7-21 12-30s13-17 21-23c9-6 20-8 32-8 35 0 54 16 60 50zM1218 971v403h81v-153c0-30 4-51 14-64s26-20 48-20c19 0 32 6 40 18 7 12 11 30 11 54v165h80v-180c0-18-1-34-5-49-3-15-8-28-16-38s-19-18-33-24c-13-6-31-9-53-9-15 0-30 4-46 12-16 7-29 20-39 37h-1v-152zM1606 1248h210c2-23 0-45-5-65-6-21-14-40-26-56s-27-29-46-38c-18-10-40-15-65-15-22 0-42 4-60 12s-34 19-47 32c-14 14-24 30-31 49s-11 39-11 61c0 23 4 44 11 62 7 19 17 35 30 49 12 13 28 24 46 31 19 8 40 11 62 11 34 0 62-7 85-22s41-40 52-75h-70c-3 9-10 17-22 25s-26 12-42 12c-22 0-40-5-52-17s-18-31-19-56zM1736 1197h-130c0-6 1-12 3-20 2-7 6-13 11-20 5-6 12-12 20-16 9-4 19-6 32-6 20 0 34 5 44 15 10 11 16 26 20 47zM1850 1082v292h80v-132c0-13 2-25 4-36 3-12 7-22 13-30 7-8 15-15 25-20s23-7 37-7c5 0 10 0 15 0 6 1 10 2 14 2v-74c-6-2-12-3-17-3-11 0-20 2-30 5-9 3-18 7-26 12-9 6-16 12-22 20-7 8-12 16-16 25h-1v-54zM2333 1082v-87h-80v87h-49v54h49v172c0 15 2 26 7 35s11 16 20 21c8 5 18 9 29 10 11 2 23 3 36 3 7 0 16 0 24-1 8 0 16-1 22-2v-62c-3 1-7 1-11 2-5 0-9 0-13 0-14 0-23-2-28-7-4-4-6-13-6-27v-144h58v-54zM2493 1172c1-16 7-27 16-34s21-10 37-10c7 0 14 0 20 1s12 3 16 6c5 3 9 7 12 12s4 12 4 20c0 9-2 15-7 19-6 5-13 8-22 10s-19 4-31 5-23 3-35 5-24 4-36 7-23 8-32 15c-9 6-17 15-22 25-6 11-9 25-9 41 0 15 2 28 7 39s13 20 22 27c9 8 19 13 31 16 12 4 25 5 39 5 18 0 36-2 53-8 18-5 33-14 45-27 1 5 1 9 2 14s3 9 4 14h81c-3-6-6-15-8-27-1-12-2-25-2-38v-152c0-18-4-32-12-43-8-10-18-19-30-25-13-6-26-10-41-12s-30-3-45-3c-16 0-32 2-48 5s-31 9-43 16c-13 8-24 18-32 30s-13 28-14 47zM2598 1261c0 5-1 11-1 18-1 8-4 15-8 22-4 8-11 14-19 19-9 6-21 8-37 8-6 0-13 0-19-1-6-2-11-4-15-6-5-3-8-7-11-12s-4-11-4-18c0-8 1-14 4-19s6-9 10-12c5-3 10-6 16-7 5-2 11-4 17-5 7-1 13-2 20-3 6-1 12-1 18-3 6-1 11-2 16-4s10-4 13-7zM2729 971v403h80v-403zM2921 1279h-76c0 20 5 36 13 49s18 23 31 31 27 14 43 17c16 4 33 5 50 5 16 0 33-1 49-5 16-3 30-8 42-16 13-8 23-18 30-31 8-13 12-30 12-49 0-13-3-25-8-34s-12-17-21-23c-8-6-18-11-29-15s-23-7-35-10c-11-2-22-5-33-7s-20-5-29-8c-8-2-15-6-21-11-5-4-7-10-7-17 0-6 1-11 4-15 3-3 7-6 11-8s9-3 14-3c6-1 11-1 15-1 14 0 27 3 37 8 11 5 17 16 18 31h76c-1-18-6-33-14-45-7-11-17-21-29-28-11-7-25-12-40-15-14-3-30-5-46-5-15 0-31 2-46 4-15 3-28 8-41 15-12 7-21 16-29 29-7 12-11 27-11 46 0 13 3 23 8 32 6 9 13 16 21 22 9 6 19 11 30 14 11 4 22 7 34 10 29 6 51 12 67 18s24 15 24 27c0 7-2 13-5 18-4 4-8 8-13 11s-11 5-17 6c-6 2-12 2-18 2-8 0-15-1-22-3-8-1-14-4-20-8s-10-9-14-16c-3-6-5-13-5-22zM3148 1082v394h81v-138h1c9 14 22 25 37 32 15 8 32 11 50 11 22 0 40-4 56-12s30-19 40-33c11-14 19-30 24-48 6-19 8-37 8-57 0-21-2-40-8-59-5-19-13-36-24-50-11-15-25-26-41-35-17-9-36-13-59-13-18 0-35 4-50 11s-28 18-37 34h-1v-37zM3296 1321c-13 0-24-2-33-7-9-6-16-13-22-21-5-9-9-18-12-30-2-11-3-22-3-34s1-24 3-35 6-21 12-30c5-9 12-16 21-21 9-6 20-8 33-8s24 2 33 8c8 5 16 12 21 21 6 9 10 19 12 30 3 12 4 23 4 35s-1 23-3 34c-3 12-6 21-12 30-5 8-12 15-21 21-9 5-20 7-33 7zM3546 1248h210c2-23 0-45-5-65-6-21-14-40-26-56s-27-29-46-38c-18-10-40-15-64-15-23 0-43 4-61 12s-34 19-47 32c-13 14-24 30-31 49s-10 39-10 61c0 23 3 44 10 62 7 19 17 35 30 49 12 13 28 24 47 31 18 8 39 11 62 11 33 0 61-7 84-22 24-15 41-40 52-75h-70c-3 9-10 17-22 25-11 8-25 12-42 12-22 0-39-5-52-17-12-12-18-31-19-56zM3676 1197h-130c0-6 1-12 3-20 2-7 6-13 11-20 5-6 12-12 20-16 9-4 20-6 32-6 20 0 34 5 44 15 10 11 16 26 20 47zM3790 1082v292h80v-132c0-13 2-25 4-36 3-12 7-22 14-30 6-8 14-15 24-20s23-7 37-7c5 0 10 0 16 0 5 1 9 2 13 2v-74c-6-2-12-3-17-3-11 0-20 2-30 5-9 3-18 7-26 12-9 6-16 12-22 20-7 8-12 16-16 25h-1v-54zM3996 1082v292h80v-132c0-13 2-25 4-36 3-12 7-22 14-30 6-8 14-15 24-20s23-7 37-7c5 0 10 0 16 0 5 1 9 2 13 2v-74c-6-2-12-3-17-3-10 0-20 2-30 5-9 3-18 7-26 12-8 6-16 12-22 20-7 8-12 16-15 25h-2v-54zM4258 1248h211c1-23-1-45-6-65-5-21-14-40-26-56s-27-29-45-38c-19-10-40-15-65-15-22 0-42 4-61 12-18 8-34 19-47 32-13 14-23 30-30 49s-11 39-11 61c0 23 3 44 10 62 7 19 17 35 30 49 13 13 28 24 47 31 18 8 39 11 62 11 33 0 61-7 85-22 23-15 40-40 52-75h-71c-3 9-10 17-21 25-12 8-26 12-42 12-23 0-40-5-52-17s-19-31-20-56zM4389 1197h-131c0-6 2-12 4-20 2-7 5-13 10-20 6-6 12-12 21-16 8-4 19-6 32-6 19 0 34 5 43 15 10 11 17 26 21 47zM136 437h-108c1 28 8 51 19 69 12 19 26 33 44 45 18 11 38 19 61 24 23 4 47 7 71 7 23 0 46-2 69-7 23-4 43-12 60-24 18-11 32-26 43-44s17-41 17-68c0-20-4-36-12-49-7-13-17-24-29-33-12-8-26-15-42-21-16-5-32-10-49-13-16-4-31-8-47-11-15-3-29-7-41-11s-22-9-29-15c-8-7-11-15-11-25 0-9 2-15 6-20 4-6 9-9 16-12 6-3 13-4 20-5s14-1 21-1c20 0 38 3 53 11s23 23 24 45h108c-2-26-8-47-19-64s-25-30-41-41c-17-10-36-17-57-21s-43-7-65-7-44 2-66 6c-21 4-40 11-57 21s-31 24-41 41c-11 17-16 39-16 65 0 18 4 34 11 46 8 13 18 23 30 32 12 8 26 15 42 20s32 9 48 13c41 8 72 17 95 25 23 9 34 22 34 39 0 10-2 18-7 25s-11 12-18 16-15 7-24 9-17 3-25 3c-12 0-22-2-33-4-10-3-19-7-27-13-8-5-15-13-20-21-5-9-8-20-8-32zM554 392h298c3-32 0-62-8-92-7-29-19-55-36-78s-38-42-64-55c-27-14-57-21-92-21-32 0-60 6-86 17s-49 27-67 46c-19 20-33 43-43 70-11 26-16 55-16 86 0 32 5 61 15 88s24 50 42 69 40 34 67 44c26 11 55 16 88 16 47 0 87-11 120-32s57-57 73-107h-100c-3 13-14 25-30 37-17 11-36 17-59 17-32 0-57-8-74-25-17-16-26-43-28-80zM739 320h-185c1-8 2-17 5-27s8-20 15-29c8-9 17-17 29-23s27-9 45-9c28 0 49 8 62 23 14 14 24 36 29 65zM1300 545v-387h-108v55h-2c-14-24-31-41-52-51-20-10-44-16-71-16-29 0-54 6-77 17-22 11-40 27-55 45-15 19-26 41-34 66s-12 51-12 77c0 29 4 55 10 81 7 25 17 47 32 66 14 19 33 34 55 45s49 16 80 16c25 0 49-5 72-15 22-11 40-27 52-49h2v55c0 29-7 54-22 73-14 19-38 29-70 29-20 0-38-5-53-13-16-8-26-23-31-44h-113c1 23 8 43 19 60 12 17 26 31 44 41 17 11 36 19 57 24s42 8 62 8c48 0 86-7 114-20 28-12 50-28 65-46 15-19 24-39 29-60 4-21 7-40 7-57zM1095 474c-18 0-32-4-44-11-12-8-21-17-29-29-7-12-12-25-15-40-3-14-4-29-4-44 0-16 2-31 5-45 4-14 9-26 17-37s17-20 29-26c11-7 25-10 41-10 19 0 34 4 46 11 13 6 22 16 30 28 7 11 13 25 16 40s5 31 5 48c0 15-2 30-6 43-4 14-10 26-18 37-8 10-18 19-31 25-12 7-26 10-42 10zM1467 392h298c2-32 0-62-8-92-7-29-19-55-36-78s-38-42-64-55c-27-14-57-21-92-21-32 0-61 6-87 17-25 11-48 27-66 46-19 20-33 43-44 70-10 26-15 55-15 86 0 32 5 61 15 88s24 50 42 69 40 34 66 44c27 11 56 16 88 16 47 0 87-11 121-32 33-21 57-57 73-107h-100c-4 13-14 25-30 37-17 11-37 17-59 17-33 0-57-8-74-25-17-16-26-43-28-80zM1652 320h-185c0-8 2-17 5-27s8-20 15-29 17-17 29-23 27-9 45-9c28 0 49 8 62 23 14 14 23 36 29 65zM1818 0v571h114v-571zM1999 304v98h216v-98zM2923 571v-413h-113v217c0 42-7 72-21 90-14 19-36 28-67 28-27 0-46-8-57-25s-16-42-16-77v-233h-114v254c0 26 3 49 7 70 5 21 13 39 24 54s26 26 46 34c19 8 44 12 75 12 24 0 47-5 70-16s42-28 56-52h2v57zM2991 158v413h113v-216c0-43 7-73 21-91 14-19 36-28 67-28 27 0 46 9 57 25 11 17 16 43 16 77v234h114v-255c0-26-3-49-7-70-5-21-13-39-24-54-11-14-26-26-46-34-19-8-44-13-75-13-24 0-47 6-70 17s-42 28-56 52h-2v-57zM3741 519v52h108v-571h-114v208h-1c-13-20-30-36-53-46-22-10-45-16-70-16-30 0-57 6-80 18s-42 28-57 48-26 43-34 69c-8 25-12 52-12 80 0 29 4 57 12 83 8 27 19 51 34 71 15 21 35 37 58 49 24 12 51 18 82 18 27 0 51-5 73-15s39-26 52-48zM3739 363c0 17-1 34-4 50-4 16-9 30-16 43-8 12-18 22-30 30-13 7-29 11-47 11s-33-4-45-12c-13-7-23-17-32-30-8-13-14-27-18-43-3-16-5-32-5-48 0-17 2-33 5-49s9-30 17-42 18-22 31-30c12-7 28-11 47-11 18 0 34 4 46 11 12 8 23 18 30 30 8 12 13 25 17 41 3 16 4 32 4 49zM4192 0v571h114v-142l44-42 113 184h138l-174-261 156-152h-134l-143 149v-307zM4731 285c2-22 9-38 22-48s30-14 53-14c10 0 20 0 28 2 9 1 17 4 24 8 6 4 12 9 16 16 4 8 6 17 6 30 0 11-3 20-11 26-7 6-17 11-30 14-13 4-28 6-44 8-17 1-34 3-51 6s-34 6-50 11c-17 4-32 11-45 20s-24 21-32 37c-9 15-13 34-13 58 0 21 4 39 11 55 7 15 17 28 30 38s28 18 45 23c17 4 35 7 55 7 26 0 51-4 75-11 25-8 46-21 64-40 1 7 2 14 3 21s3 13 5 20h116c-6-9-10-22-12-39s-3-35-3-54v-215c0-25-5-45-17-60-11-16-25-27-43-36-17-8-37-14-58-17-22-3-43-5-63-5-23 0-46 3-69 7-23 5-43 12-61 23s-33 25-45 43c-12 17-18 39-20 66zM4880 411c0 7-1 15-2 26-2 11-5 21-11 32-6 10-15 19-27 26-13 8-30 12-52 12-10 0-18-1-27-3-8-1-16-4-22-8-7-4-12-10-16-17-3-6-5-15-5-25 0-11 2-20 5-27 4-7 9-12 15-17 6-4 14-8 22-11 8-2 17-4 25-6 9-2 18-3 27-4s18-2 26-4c9-2 16-4 24-6 7-2 13-6 18-10zM5062 158v413h114v-216c0-43 6-73 20-91 14-19 37-28 68-28 27 0 46 9 56 25 11 17 16 43 16 77v234h114v-255c0-26-2-49-7-70-4-21-12-39-23-54-12-14-27-26-46-34-20-8-45-13-75-13-24 0-48 6-71 17s-41 28-56 52h-2v-57zM5905 571v-413h-113v217c0 42-7 72-21 90-14 19-37 28-67 28-28 0-47-8-57-25-11-17-16-42-16-77v-233h-114v254c0 26 2 49 7 70 4 21 12 39 24 54 11 15 26 26 46 34 19 8 44 12 74 12 24 0 48-5 71-16s41-28 56-52h2v57zM5967 304v98h217v-98zM6646 545v-387h-108v55h-2c-14-24-31-41-51-51-21-10-45-16-72-16-29 0-54 6-76 17-23 11-41 27-56 45-15 19-26 41-34 66s-12 51-12 77c0 29 4 55 10 81 7 25 18 47 32 66s33 34 55 45c23 11 49 16 80 16 25 0 49-5 72-15 22-11 40-27 52-49h2v55c0 29-7 54-21 73-15 19-38 29-70 29-21 0-39-5-54-13s-26-23-31-44h-113c2 23 8 43 20 60 11 17 25 31 43 41 17 11 36 19 57 24s42 8 62 8c48 0 86-7 114-20 28-12 50-28 65-46 15-19 24-39 29-60s7-40 7-57zM6441 474c-18 0-32-4-44-11-12-8-21-17-28-29-8-12-13-25-16-40-3-14-4-29-4-44 0-16 2-31 5-45 4-14 9-26 17-37s17-20 29-26c11-7 25-10 41-10 19 0 34 4 46 11 13 6 23 16 30 28 7 11 13 25 16 40s5 31 5 48c0 15-2 30-6 43-4 14-10 26-18 37-8 10-18 19-31 25-12 7-26 10-42 10zM6811 392h299c2-32-1-62-8-92-8-29-20-55-37-78-16-23-38-42-64-55-26-14-57-21-92-21-31 0-60 6-86 17s-48 27-67 46c-18 20-33 43-43 70-10 26-15 55-15 86 0 32 5 61 15 88 9 27 23 50 42 69 18 19 40 34 66 44 26 11 55 16 88 16 47 0 87-11 120-32s58-57 74-107h-100c-4 13-14 25-31 37-16 11-36 17-59 17-32 0-57-8-74-25-17-16-26-43-28-80zM6996 320h-185c1-8 3-17 6-27s8-20 15-29 17-17 29-23 27-9 45-9c28 0 48 8 62 23 13 14 23 36 28 65zM7161 158v413h114v-240c0-20 3-36 8-49 6-12 13-22 22-29 8-6 16-11 25-13 9-3 16-4 21-4 19 0 32 3 42 9 9 6 16 15 20 25s6 21 6 33c1 12 1 24 1 36v232h114v-230c0-13 1-26 3-38 1-13 5-24 11-34 5-10 13-18 23-24s23-9 39-9 29 3 38 8 16 13 21 22 8 19 9 32c1 12 1 25 1 39v235h114v-277c0-27-4-50-11-69-8-19-18-34-31-46-14-12-30-20-48-26-19-5-39-8-61-8-29 0-54 7-75 21s-38 30-50 48c-11-25-28-43-49-53-22-10-46-16-72-16-27 0-51 6-72 18s-39 28-54 50h-2v-56zM7957 392h298c3-32 0-62-8-92-7-29-19-55-36-78s-38-42-64-55c-26-14-57-21-92-21-32 0-60 6-86 17s-48 27-67 46c-19 20-33 43-43 70-10 26-16 55-16 86 0 32 5 61 15 88s24 50 42 69 41 34 67 44c26 11 55 16 88 16 47 0 87-11 120-32s57-57 73-107h-100c-3 13-14 25-30 37-17 11-36 17-59 17-32 0-57-8-74-25-17-16-26-43-28-80zM8142 320h-185c1-8 2-17 5-27s8-20 15-29c8-9 17-17 29-23s27-9 45-9c28 0 49 8 62 23 14 14 24 36 29 65zM8420 94v-94h-113v94zM8307 158v413h113v-413zM8491 158v413h113v-216c0-43 7-73 21-91 14-19 36-28 67-28 28 0 46 9 57 25 11 17 16 43 16 77v234h114v-255c0-26-3-49-7-70-5-21-12-39-24-54-11-14-26-26-46-34-19-8-44-13-74-13-24 0-48 6-71 17s-42 28-56 52h-2v-57zM9034 437h-108c1 28 7 51 19 69 11 19 26 33 44 45 18 11 38 19 61 24 23 4 46 7 70 7s47-2 70-7c22-4 42-12 60-24 18-11 32-26 43-44s16-41 16-68c0-20-4-36-11-49-8-13-17-24-30-33-12-8-26-15-42-21-15-5-32-10-48-13-16-4-32-8-47-11-16-3-29-7-41-11s-22-9-30-15c-7-7-11-15-11-25 0-9 2-15 7-20 4-6 9-9 15-12s13-4 20-5c8-1 15-1 21-1 21 0 38 3 53 11s23 23 25 45h108c-2-26-9-47-20-64s-24-30-41-41c-16-10-35-17-56-21s-43-7-65-7c-23 0-45 2-66 6s-41 11-58 21-30 24-41 41c-10 17-16 39-16 65 0 18 4 34 12 46 7 13 17 23 29 32 13 8 27 15 42 20 16 5 32 9 49 13 40 8 72 17 95 25 22 9 34 22 34 39 0 10-3 18-8 25-4 7-10 12-18 16-7 4-15 7-24 9-8 2-17 3-25 3-11 0-22-2-32-4-11-3-20-7-28-13-8-5-14-13-19-21-6-9-8-20-8-32zM9638 303h111c-1-26-8-49-19-69-11-19-26-36-44-49-17-13-38-23-60-29-23-6-47-10-71-10-34 0-64 6-90 17s-48 27-66 47-32 44-41 71c-10 28-14 58-14 90 0 31 5 59 15 85s24 48 42 67c18 18 40 33 66 43 26 11 54 16 85 16 55 0 100-14 136-43 35-29 56-71 64-126h-110c-4 26-13 46-28 61-14 15-35 23-62 23-18 0-33-4-45-12-13-8-22-18-29-31-8-12-13-26-16-42-3-15-5-30-5-45 0-16 2-31 5-47s9-30 16-43c8-14 18-24 30-32 13-9 28-13 46-13 49 0 76 24 84 71zM9796 0v571h114v-216c0-43 7-73 21-91 14-19 36-28 67-28 27 0 46 9 57 25 10 17 16 43 16 77v234h113v-255c0-26-2-49-6-70-5-21-13-39-24-54-11-14-27-26-46-34s-44-13-75-13c-21 0-43 6-65 17-23 11-41 28-56 52h-2v-215zM10360 285c3-22 10-38 23-48s30-14 53-14c10 0 19 0 28 2 9 1 17 4 23 8 7 4 12 9 16 16 4 8 6 17 6 30 1 11-3 20-10 26-8 6-18 11-31 14-12 4-27 6-44 8-16 1-33 3-50 6s-34 6-51 11c-17 4-32 11-45 20s-23 21-32 37c-8 15-12 34-12 58 0 21 4 39 11 55 7 15 17 28 30 38s28 18 45 23c17 4 35 7 55 7 25 0 50-4 75-11 25-8 46-21 64-40 1 7 1 14 3 21 1 7 3 13 5 20h115c-5-9-9-22-11-39s-3-35-3-54v-215c0-25-6-45-17-60-11-16-26-27-43-36-18-8-37-14-59-17-21-3-42-5-63-5-23 0-45 3-68 7-23 5-43 12-61 23-19 11-33 25-45 43-12 17-19 39-20 66zM10509 411c0 7 0 15-2 26-1 11-5 21-11 32-5 10-14 19-27 26-12 8-29 12-52 12-9 0-18-1-26-3-9-1-16-4-23-8-6-4-11-10-15-17-4-6-5-15-5-25 0-11 1-20 5-27s9-12 15-17c6-4 13-8 22-11 8-2 16-4 25-6s18-3 27-4 18-2 26-4 16-4 23-6 13-6 18-10zM10716 234v337h114v-337h78v-76h-78v-25c0-17 3-29 10-37 7-7 18-10 33-10s28 0 42 2v-85c-10 0-20-1-30-2s-20-1-30-1c-47 0-81 12-104 35-23 24-35 54-35 91v32h-68v76zM11083 158v-124h-114v124h-69v76h69v244c0 21 4 37 11 50s16 23 28 30 26 11 42 14c15 2 32 3 50 3 11 0 22 0 34 0 12-1 22-2 32-4v-88c-5 2-11 2-17 3-6 0-12 1-18 1-19 0-32-4-39-10-6-6-9-19-9-38v-205h83v-76zM11508 392h298c2-32 0-62-8-92-7-29-20-55-36-78-17-23-39-42-65-55-26-14-56-21-92-21-31 0-60 6-86 17s-48 27-67 46c-18 20-33 43-43 70-10 26-15 55-15 86 0 32 5 61 15 88s24 50 42 69 40 34 66 44c26 11 56 16 88 16 47 0 87-11 120-32s58-57 74-107h-100c-4 13-14 25-30 37-17 11-37 17-60 17-32 0-56-8-73-25-17-16-27-43-28-80zM11692 320h-184c0-8 2-17 5-27s8-20 15-29 17-17 29-23 27-9 45-9c28 0 49 8 62 23 14 14 23 36 28 65zM11846 448v123h126v-123zM12369 571l140-413h-113l-87 282h-2l-87-282h-120l142 413zM12469 448v123h126v-123z">
    <text:p/>
   </draw:path>
   <text:p text:style-name="P55">Stegdienst <text:span text:style-name="T39"><%= substr $start, 0, 4 %></text:span></text:p>
   <table:table table:name="Table1" table:style-name="Table1">
    <table:table-column table:style-name="Table1.A"/>
    <table:table-column table:style-name="Table1.B"/>
    <table:table-column table:style-name="Table1.C"/>
    <table:table-column table:style-name="Table1.D"/>
    <table:table-header-rows>
     <table:table-row>
      <table:table-cell table:style-name="Table1.A1" office:value-type="string">
       <text:p text:style-name="Table_20_Heading">Datum ab</text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Table1.A1" table:number-columns-spanned="2" office:value-type="string">
       <text:p text:style-name="Table_20_Heading">Stegdienst-Team</text:p>
      </table:table-cell>
      <table:covered-table-cell/>
      <table:table-cell table:style-name="Table1.D1" office:value-type="string">
       <text:p text:style-name="Standard"/>
      </table:table-cell>
     </table:table-row>
    </table:table-header-rows>
% for (my $i = 0; $i < scalar @$liste; $i++) {
    <table:table-row>
%  if ($i) {
     <table:table-cell table:style-name="Table1.A2" office:value-type="date" table:formula="&lt;A<%= $i + 1 %>&gt;+7">
%  } else {
     <table:table-cell table:style-name="Table1.A2" office:value-type="date" office:date-value="<%= $start %>">
%  }
      <text:p text:style-name="Stegdienst-Datum"/>
     </table:table-cell>
     <table:table-cell table:style-name="Table1.B2" office:value-type="string">
      <text:p text:style-name="Standard"><%= $liste->[$i]->[0] %></text:p>
     </table:table-cell>
     <table:table-cell table:style-name="Table1.C2" office:value-type="string">
      <text:p text:style-name="Standard"><%= $liste->[$i]->[1] %></text:p>
     </table:table-cell>
     <table:table-cell table:style-name="Table1.D1" office:value-type="string">
      <text:p text:style-name="Standard"/>
     </table:table-cell>
    </table:table-row>
% }
   </table:table>
   <text:p text:style-name="P5">Der Teamwechsel ist mittwochs, damit der Steg noch vor dem Wochenende gereinigt und ggf. versetzt werden kann. Die Jugendgruppe trifft sich samstags und freut sich darüber.</text:p>
   <text:p text:style-name="P5"><text:span text:style-name="Strong_20_Emphasis">Vorsicht mit dem Hochdruckreiniger</text:span> – nicht ins Wasser kippen lassen!</text:p>
   <text:p text:style-name="P5">Eintragungen im Stegbuch müssen lesbar mit Namen versehen werden. Ansonsten ist eine Berücksichtigung bei der Auswertung u. U. nicht möglich.</text:p>
   <text:p text:style-name="Date-Signature"><text:span text:style-name="Small">Stand: <%= $stand %></text:span></text:p>
  </office:text>
 </office:body>
</office:document>

<!--<%= $export %>-->
