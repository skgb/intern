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
- LISTEN interface implemented

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
- brand new Neo4j driver set to replace Neo4p, including plug-in support (API not finalised)
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

2.0.0-a16, 2016-12-27
- refactor SessionManager -> AccessCode, using SKGB::Intern::Person rather than SKGB::Intern::Model::Person
- minor fixes to import tool and weather page

2.0.0-a17, 2017-01-06
- fix authentication to respect RFCs 7234 and 7235
- Auth.pm uses the new AccessCode class
- initial very rough implementation of downgrade and sudo (buggy)
- some work towards budget report
- minor fixes

2.0.0-a18, 2017-01-07
- regression fix: a minor roles change in 2.0.0-a17 made it impossible to order new access codes in the key factory
- regression fix: a minor roles change in 2.0.0-a17 made the membership status hard to read in some of the list views
- restrict access to association password

2.0.0-a19, 2017-01-10
- fix may for other users
- fix board column in 'stegdienstliste' query

2.0.0-a20, 2017-01-17
- implemented budget report / member fee list view
- moved SKGB::Intern::Model::Person -> SKGB::Intern::Person::Neo4p for clarity
- refactored membership code out of SKGB::Intern::Person into SKGB::Intern::Model::Membership

2.0.0-a21, 2017-01-28
- login limitation ('fail2ban' concept)
- refactor send mail code
- refactor AccessCode (key/session expiration and access time update)
- fix long-standing login failure for valid keys with expired sessions
- custom exception and not-found pages
- not found redirect mechanism
- implement Perl boolean support in Neo4j driver
- implement includeStats support in Neo4j driver/plugin

2.0.0-a22, 2017-02-09
- implement berth list view
- GS-Verein/Paradox view
- change import.pl to accept pxtools XML as well as ALLES input format
- security fix: auth code no longer leaks into the URL
- bugfix in Neo4j plugin: get-persons works when the person column has NULL values (for OPTIONAL MATCH queries)

2.0.0-a23, 2017-02-14
- regression fix: refactoring AccessCode in 2.0.0-a21 lead to a run-time error in calculating the elapsed time since a key expired

2.0.0-a24, 2017-03-02
- support Paradox archive import
- include membership status in postal address list view
- more explicit association statistics guidance
- tooltips in GS-Verein/Paradox view
- allow login with leading/trailing white space in access code
- minor additional robustness improvements
- regression fix for 2.0.0-a22: auth code in URL is now RESTful and produces stable links even on 403 pages

2.0.0-a25, 2017-06-15
- tri-state auth logic (access / no authn / no authz) with brightly coloured lock icons
- support CommonMark and internal links with auth logic in Wiki
- nearly stable base implementation of new auth framework based exclusively on roles rather than named rights, resulting in a simpler model (secure access codes and role negation are not well tested and have issues remaining however)
- graph view of role tree
- fix postal address list view to only display those few addresses usually needed by default
- fix the logout button's POST form introduced in 2.0.0-a12 to work in Firefox
- fix 500 error in list\_berth template
- improve routing setup (cleaner code and 405 Method Not Allowed responses to non-GET/POST requests)
- significantly improve Paradox archive import performance
- minor copy and UI updates, minor code cleanup

2.0.0-a26, 2017-07-03
- implemented club keys list view

2.0.0-a27, 2017-07-20
- reverse proxy to version 1.4 (legacy plugin)
- add debit reason to budget report view
- hide key details in key list when the key has been returned and deposit payback is the only thing left to do
- improve style sheet (lock icons, yellow mark)
- improve error handling in Neo4j driver
- minor refactoring (Person object, 403 response, import)

2.0.0-a28, 2018-01-15
- implement board decision of 2017-09-23 to use email addresses of legal guardians for important mailings if a member doesn't have an email address of their own
- add key issue date to provisional person "node" report
- update for 2018 ("Stegdienstliste", import, GS-Verein view, berth assignments)
- fix "Stegdienstliste" to exempt members who have joined the very same year (these are usually exempt simply by not joining until after the list has been created; this fix takes care of those few that happen to join in the first days of the year)
- auto-reset stored password for version 1.4 proxy if we are 401 Unauthorized
- fix person endpoints to support node id 0
