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
