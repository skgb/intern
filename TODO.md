MUSS in 2.0 (während ALPHA):
----------------------------
(= Blocker für Ende Alpha-Phase)

- [ ] Auth komplett
- [ ] "secure session": extremely important; general idea: Require voice confirmation (just by admins) *and* a relatively fresh access code (e. g. less than 20 mins or so) to lessen the risk of someone stealing the code before auth can take place
- [ ] Wiki: simpel, aber mit Auth (inkl. Links)
- [ ] Wiki: Dateianhänge
- [ ] neuer Personen-Bericht (Optik + zuverlässige Inhalte)



SOLL in 2.0 (spätestens während BETA, besser noch während ALPHA):
-----------------------------------------------------------------

- [X] Konzept für intern1-Einbindung aufstellen



SOLL in 2.0 (während BETA):
---------------------------

- [ ] neues Design
- [ ] Neo4j-Driver ausgliedern
- [ ] Tests, Doku, Refactoring
- [ ] wichtige Daten aus 1.x ins Wiki übernehmen
- [ ] AccessCodes: srand, Dictionary-Scan



DARF in 2.0 (während BETA):
---------------------------

- [ ] Wiki: Vorschau, Diff
- [ ] intern1-Einbindung
- [ ] restliche Daten und Medien aus 1.x ins Wiki übernehmen
- [ ] improved security: use initial AccessCode as a ONE TIME password, which is slightly less user-friendly, but could then be transitioned to a second code as a more secure session key (not sure if this is worth the effort)
- [ ] Telefonnummern-Inverssuche



NICHT in 2.0 (späteres Update):
-------------------------------

- Endpoints (/boot, /box, /schluessel etc)
- Endpoints: Links mit Wiki-Seiten (übers Boot, die Person etc)
- Endpoints: Permalinks (insb. auch für Nodes ohne Handle) (e. g. a running id tracked by :System, e. g. /access-code/142; even better: running count in :Person with URL like /person/abc/access-code/54; node ID is not just as good, since high-security codes will outlive backups in the future, but this is possibly an edge case)
- Daten bearbeiten: über Endpoints? REST?
- Wiki: Mail-Abos
