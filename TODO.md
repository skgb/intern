MUSS in 2.0 (während ALPHA):
----------------------------
(= Blocker für Ende Alpha-Phase)

- [ ] **Auth komplett**
- [ ] **"secure session": extremely important; general idea: Require voice confirmation (just by admins) *and* a "stored" session (which implies that each "normal" access code can only be used *once* to create a stored session)**
- [ ] Wiki: simpel, aber mit Auth (inkl. Links)
- [ ] Wiki: Dateianhänge
- [ ] neuer Personen-Bericht (für Vorstand) (nicht optimale, aber bessere Optik + zuverlässige Inhalte)



SOLL in 2.0 (spätestens während BETA, besser noch während ALPHA):
-----------------------------------------------------------------

- [X] Konzept für intern1-Einbindung aufstellen

intern1-Einbindung:

- Arbeitsverzeichnis auf dem Server: legacy
- [X] Reverse Proxy
- [X] beim Zugriff Passwort aus :Person holen
- [X] falls nicht existent: crypt-Passwort erzeugen, in :Person als Klartext ablegen und in htpasswd schreiben (mit DigestAuth.pm-Code)
- [X] wird beim Database-Drop gelöscht und muss neu erzeugt werden: kein Problem
- Zugriff beschränken auf Clyde (= nur Reverse Proxy aus intern2)
- [X] Account-Manager abschalten/kastrieren (Passwortänderung darf nicht möglich sein, sonst sperrt man sich aus)
- [X] alle Links so ändern, dass sie ohne unnötige Redirects passen (= /digest löschen)
- [X] provisorisch: Masthead klar kennzeichnen (1/2), Link im Menü "wechseln zu 1/2"
- [ ] email, sepa, update
- später alle Inhalte in den Hauptmenüs von 1 nach 2 migrieren; übrig bleiben im Wesentlichen nur Medien, E-Mails und SEPA, wofür man kein eigenes Menü braucht
- [ ] evtl. Zugriffsberechtigung auf intern1 generell (Zugriff nur für Mitglieder) manuell prüfen, falls der Reverse Proxy nicht automatisch erfasst werden kann (prüfen!)
- [ ] Cache-Control: no-cache

https://tools.ietf.org/html/rfc2617#section-2
https://tools.ietf.org/html/rfc2616#section-2.2



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
- [ ] Personen-Profil (für Mitglieder) mit Einstellung der Sichtbarkeit von Einzelangaben
- [ ] Bug in LISTEN-Schnittstelle: Neuaufnahmen haben keine Telefonnummern
- [ ] Die SKGB-Adressen-Logik sollte jetzt in der GS-Verein-Schnittstelle korrekt sein; vereinheitlichen mit node-Report und LISTEN-Schnittstelle



NICHT in 2.0 (späteres Update):
-------------------------------

- Endpoints (/boot, /box, /schluessel etc)
- Endpoints: Links mit Wiki-Seiten (übers Boot, die Person etc)
- Endpoints: Permalinks (insb. auch für Nodes ohne Handle) (e. g. a running id tracked by :System, e. g. /access-code/142; even better: running count in :Person with URL like /person/abc/access-code/54; node ID is not just as good, since high-security codes will outlive backups in the future, but this is possibly an edge case)
- Daten bearbeiten: über Endpoints? REST?
- Wiki: Mail-Abos
