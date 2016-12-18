CHANGES
=======

2.0.0_1, 2016-04-24
first preview release:
- basic auth logic and key factory
- member list view
- profile page with limited information on individuals
- export to intern1

2.0.0_2, 2016-04-25
- fixed from/return addresses in key factory email

2.0.0_3, 2016-04-25
- activated persistent local storage for member list view

2.0.0_4, 2016-05-14
- fixed bug in membership date calculation in SKGB::Intern::Model::Person

2.0.0-a5, 2016-05-27
various hidden/internal changes:
- support for SKGB::Regeln
  (still TBD: GUI feedback onChange of version list; SVG embedding; content QA; raw switch doesn't always work)
- some work towards wiki (nowhere near finished - particularly diff and file attachments are still TBD)
- key factory shortcut 'aj'
- support for DOSB interface / association statistics (still missing: boat stats and board address list for DSV)
- some work towards auth tree and auth edit (nowhere near finished)

2.0.0-a6, 2016-06-04
- LISTEN interface implemented (untested)

2.0.0-a7, 2016-06-10
- fixed bug in membership leaves date presentation (person.html.ep)

2.0.0-a8, 2016-06-13
- weather links page

2.0.0-a9, 2016-06-14
- reorganised index page and menu
- implemented postal address list view
- fixed primary:true bug in import.pl
- fixed display bug for 3+-line postal addresses on profile page
- improved warning message below profile page
- added salt to cookie security secret

2.0.0-a10, 2016-06-17
- added radar image with location dot to weather page

2.0.0-a11, 2016-08-07
- made radar image be included through HTTPS
- fixed CSS in layout to support mobile browsers (missing semicolon)
- implemented REST-style URL for individual profile pages (just as a redirect for now)

2.0.0-a12, 2016-11-18
- brand new Neo4j driver set to replace Neo4p, including plug-in support
- deprecated SKGB::Intern::Model::Person, replacement SKGB::Intern::Person is not yet fully compatible and still has Neo4p dependencies that have to be removed
- limited implementation of new auth framework based on named rights rather than URLs (AuthManager: link\_auth_to() and may(); SessionManager: access query (for compatibility); node.ep (dev mode only) and Auth.pm: incomplete experimental clients)
- new /person/* endpoint allowing RESTful addressing (so far used for permalinks and a full list view of all persons including non-members)
- implemented list view of members that are leaving the club
- implemented count of private boats in DSV stats output
- reorganised index page
- fixed logout button in menu to make a POST request instead of a GET
- fixed broken link to DWD on weather page

2.0.0-a13, 2016-12-09
- main member list shows join date rather than obsolete ID
- minor improvements to person report page (permalink handle, facade mail address, boat identification)
- minor dev mode changes (key factory logs, Auth link availability)

2.0.0-a14, 2016-12-14
- integrate app "Stegdienstliste"
- excise old IS_A* grammar
- include unfinished version of GS-Verein import script
- special-case profile page to never block access to one's own data

2.0.0-a15, 2016-12-18
- add links to association management sites
- hungarian-renamed placeholders in routes to make the mojo stash tidier
- minor internal cleanup