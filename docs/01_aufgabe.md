SQL-Aufgaben zur Datenbank reservierung_db

1. Einfache SELECT-Abfragen
   Aufgabe 1
   Gib alle Kunden mit Vorname, Nachname und Kundennummer aus.
   Aufgabe 2
   Zeige alle Adressen aus der Tabelle adresse.
   Aufgabe 3
   Gib alle Geräte mit ihrer Gerätenummer und Bezeichnung aus.
   Aufgabe 4
   Zeige alle Gerätetypen mit Bezeichnung, Preis pro Tag und Lieferpreis.
   Aufgabe 5
   Gib alle Reservierungen mit Reservierungsnummer und Datum aus.

2. Filtern mit WHERE
   Aufgabe 6
   Zeige alle Kunden, die in Limburg wohnen.
   Aufgabe 7
   Gib alle Geräte aus, die zum Gerätetyp Laptop gehören.
   Aufgabe 8
   Zeige alle Reservierungen, die nach dem 01.05.2026 angelegt wurden.
   Aufgabe 9
   Gib alle Reservierungspositionen aus, deren preis_pro_tag größer als 20 Euro ist.
   Aufgabe 10
   Zeige alle Adressen mit der Postleitzahl 65582.

3. Sortieren
   Aufgabe 11
   Gib alle Kunden alphabetisch nach Nachname sortiert aus.
   Aufgabe 12
   Zeige alle Gerätetypen nach preis_pro_tag absteigend sortiert.
   Aufgabe 13
   Gib alle Reservierungen nach Datum aufsteigend aus.

4. JOIN-Aufgaben
   Aufgabe 14
   Zeige alle Kunden mit ihrer Adresse, also Vorname, Nachname, Straße, Hausnummer, PLZ und Ort.
   Aufgabe 15
   Gib alle Geräte zusammen mit ihrem Gerätetyp aus.
   Aufgabe 16
   Zeige alle Reservierungen mit Kundennummer, Name des Kunden und Reservierungsnummer.
   Aufgabe 17
   Gib alle Reservierungspositionen mit Gerätename aus.
   Aufgabe 18
   Zeige für jede Reservierungsposition:
   Reservierungsnummer  
   Positionsnummer  
   Gerätenummer  
   Gerätebezeichnung  
   von_Datum  
   bis_Datum

5. Mehrtabellenabfragen
   Aufgabe 19
   Gib aus, welche Geräte Alice Schmidt reserviert hat.
   Aufgabe 20
   Zeige alle Reservierungen mit:
   Reservierungsnummer  
   Vorname  
   Nachname  
   Gerätename  
   Aufgabe 21
   Gib alle Kunden mit ihren Reservierungen und den jeweils reservierten Geräten aus.
   Aufgabe 22
   Zeige zu jeder Reservierungsposition auch den Ort der Lieferadresse.

6. Berechnungen
   Aufgabe 23
   Berechne für jede Reservierungsposition die Anzahl der Miettage.
   Hinweis:
   DATEDIFF(bis_datum, von_datum)
   Aufgabe 24
   Berechne für jede Reservierungsposition den Gesamtpreis nach der Formel:
   (Anzahl_Tage \* preis_pro_tag) + lieferpreis
   Aufgabe 25
   Gib für jede Reservierung die Summe aller Positionspreise aus.
   Aufgabe 26
   Berechne den Gesamtumsatz aller Reservierungen.

7. Gruppieren und Aggregatfunktionen
   Aufgabe 27
   Wie viele Kunden gibt es insgesamt?
   Aufgabe 28
   Wie viele Geräte gibt es pro Gerätetyp?
   Aufgabe 29
   Wie viele Reservierungen hat jeder Kunde?
   Aufgabe 30
   Wie viele Reservierungspositionen gibt es pro Reservierung?
   Aufgabe 31
   Welcher Gerätetyp kommt in den Reservierungen am häufigsten vor?

8. INSERT-Aufgaben
   Aufgabe 32
   Füge einen neuen Kunden mit passender Adresse ein.
   Aufgabe 33
   Füge einen neuen Gerätetyp Scanner mit Preis pro Tag und Lieferpreis ein.
   Aufgabe 34
   Füge ein neues Gerät zum Gerätetyp Scanner ein.
   Aufgabe 35
   Lege eine neue Reservierung für einen bestehenden Kunden an.
   Aufgabe 36
   Füge zu einer bestehenden Reservierung zwei neue Reservierungspositionen hinzu.

9. UPDATE-Aufgaben
   Aufgabe 37
   Ändere die Adresse von Jonas Meyer.
   Aufgabe 38
   Erhöhe den preis_pro_tag aller Beamer um 2 Euro.
   Aufgabe 39
   Ändere die Lieferkosten des Gerätetyps Drucker auf 18 Euro.
   Aufgabe 40
   Verschiebe bei einer Reservierungsposition das bis_datum um zwei Tage nach hinten.

10. DELETE-Aufgaben
    Aufgabe 41
    Lösche eine Reservierungsposition mit einer bestimmten reservierungsposition_id.
    Aufgabe 42
    Lösche eine komplette Reservierung. Überlege vorher, was mit den zugehörigen Reservierungspositionen passiert.
    Aufgabe 43
    Lösche einen Kunden nur dann, wenn keine Reservierungen mehr auf ihn verweisen.

11. Schwieriger / mit Unterabfragen
    Aufgabe 44
    Gib den Kunden aus, der die meisten Reservierungen hat.
    Aufgabe 45
    Zeige alle Geräte, die bisher noch nie reserviert wurden.
    Aufgabe 46
    Gib alle Reservierungen aus, deren Gesamtpreis über dem Durchschnitt aller Reservierungen liegt.
    Aufgabe 47
    Zeige den teuersten Gerätetyp bezogen auf preis_pro_tag.
    Aufgabe 48
    Gib alle Kunden aus, die mehr als eine Reservierung haben.
