CREATE
(user:Role {name:"User", role:"user"}),
(member:Role {name:"Mitglied", role:"member"}),
(activeMember:Role {name:"Aktives Mitglied", role:"active-member"})-[:ROLE {fee: 120}]->(member),
(passiveMember:Role {name:"Passives Mitglied", role:"passive-member"})-[:ROLE {fee: 36}]->(member),
(youthMember:Role {name:"Jugendmitglied", role:"youth-member"})-[:ROLE {fee: 35}]->(member),
(honoraryMember:Role {name:"Ehrenmitglied", role:"honorary-member"})-[:ROLE {fee: 0, noService: true, noDuties: true}]->(member),
//(guestMember:Role {name:"Gastmitglied", role:"guest-member"})-[:ROLE]->(member),
(parent:Role {name:"Sorgeberechtigter", role:"parent"}),
(collector:Role {name:"Abholberechtigter", role:"collector"}),
(boardMember:Role {name:"Vorstand", role:"board-member"}),
(execBoardMember:Role {name:"geschäftsführender Vorstand", role:"executive-board-member"})-[:ROLE]->(boardMember),
(clubHonorary:Role {name:"Ehrenvorsitzender", role:"board-honorary"})-[:ROLE]->(boardMember),
(clubPresident:Role {name:"1. Vorsitzender", role:"board-president"})-[:ROLE]->(execBoardMember),
(clubSecretary:Role {name:"2. Vorsitzender", role:"board-secretary"})-[:ROLE]->(execBoardMember),
(clubTreasurer:Role {name:"3. Vorsitzender", role:"board-treasurer"})-[:ROLE]->(execBoardMember),
(clubDeputyTreasurer:Role {name:"2. Schatzmeister", role:"board-deputy-treasurer"})-[:ROLE]->(boardMember),
(clubPressWarden:Role {name:"Pressewart", role:"board-press-warden"})-[:ROLE]->(boardMember),
(clubGearWarden:Role {name:"1. Steg- und Zeugwart", role:"board-gear-warden"})-[:ROLE]->(boardMember),
(clubDeputyGearWarden:Role {name:"2. Steg- und Zeugwart", role:"board-deputy-gear-warden"})-[:ROLE]->(boardMember),
(clubSportsWarden:Role {name:"1. Sportwart", role:"board-sports-warden"})-[:ROLE]->(boardMember),
(clubDeputySportsWarden:Role {name:"2. Sportwart", role:"board-deputy-sports-warden"})-[:ROLE]->(boardMember),
(clubYouthWarden:Role {name:"1. Jugendwart", role:"board-youth-warden"})-[:ROLE]->(boardMember),
(clubDeputyYouthWarden:Role {name:"2. Jugendwart", role:"board-deputy-youth-warden"})-[:ROLE]->(boardMember),
(admin:Role {name:"Administrator", role:"admin"})

//CREATE
//(memberData:Resource {name:'Member Data', urls:['/profile','/mitgliederliste','/anschriftenliste','/export/listen','/dosb','/regeln(?:/.*)?']})<-[:ACCESS]-(member),
//(administrative:Resource {name:'Admin', urls:['/export/intern1','/wiki(?:/.*)?']})<-[:ACCESS]-(admin),
//(login:Resource {name:'Login', urls:['/login']})<-[:ACCESS]-(user)

CREATE
//(member)-[:MAY]->(:Right {right:'member-list', name:'Mitgliederliste einsehen'}),
//(member)-[:MAY]->(:Right {right:'member-profile', name:'Mitglieder-Profilseite einsehen'}),
//(boardMember)-[:MAY]->(:Right {right:'person', name:'Personenseite einsehen'}),
//(boardMember)-[:MAY]->(:Right {right:'person-list', name:'Personenliste einsehen'}),
(execBoardMember)-[:MAY]->(paymentDataRight :Right {right:'payment-data', name:'Zahlungsdaten einsehen'}),
(clubDeputyTreasurer)-[:MAY]->(paymentDataRight),
(admin)-[:MAY]->(:Right {right:'access-log', name:'Anmeldedaten einsehen'})
CREATE
(superUser:Role {name:"Super User", role:"super-user"}),
(superUser)-[:MAY]->(:Right {right:'sudo', name:'als Super User handeln'})
CREATE
(admin)-[:MAY]->(:Right {right:'mojo:export1', name:'GS-Verein–Schnittstelle'}),
(admin)-[:MAY]->(:Right {right:'mojo:wiki', name:'Wiki (lesen und bearbeiten)'}),
(admin)-[:MAY]->(:Right {right:'mojo:wikiview', name:'Wiki (nur lesen)'}),
(user)-[:MAY]->(:Right {right:'mojo:mglpage', name:'Personen-Report (nur eigene Person)'}),
//(boardMember)-[:MAY]->(:Right {right:'mojo:mglpagenode'}),
(boardMember)-[:MAY]->(:Right {right:'mojo:mglliste', name:'Mitgliederliste'}),
(boardMember)-[:MAY]->(:Right {right:'mojo:person', name:'Personen-Report'}),
(boardMember)-[:MAY]->(:Right {right:'mojo:list_person', name:'Liste aller Personen'}),
(boardMember)-[:MAY]->(:Right {right:'mojo:list_leaving', name:'Austrittsliste'}),
(boardMember)-[:MAY]->(:Right {right:'mojo:postliste', name:'Anschriftenliste'}),
(boardMember)-[:MAY]->(:Right {right:'mojo:exportlisten', name:'Listen-Schnittstelle'}),
(execBoardMember)-[:MAY]->(dosb_Right:Right {right:'mojo:dosb', name:'Verbandsmeldungen'}),
(clubDeputyTreasurer)-[:MAY]->(dosb_Right),
(execBoardMember)-[:MAY]->(list_budget_Right:Right {right:'mojo:list_budget', name:'Einnahmenliste'}),
(clubDeputyTreasurer)-[:MAY]->(list_budget_Right),
(member)-[:MAY]->(:Right {right:'mojo:regeln', name:'SKGB-Regeln'}),
(member)-[:MAY]->(:Right {right:'mojo:stegdienstliste', name:'Stegdienstliste erzeugen'}),
(user)-[:MAY]->(:Right {right:'login'}),
(user)-[:MAY]->(:Right {right:'mojo:auth'})
