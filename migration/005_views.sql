/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:      005_views.sql
-- PROJEKT:     Reservierung DB
-- ZIELSETZUNG: Views für verschiedene Anwendungsfälle
-- ============================================================
USE reservierung_db;
/*!40101 SET NAMES utf8mb4 */;

-- ============================================================
-- OPERATIONAL VIEWS
-- ============================================================

-- ============================================================
-- VIEW:      view_verfuegbarkeit
-- ZWECK:     Zeigt alle physisch verfügbaren Geräte
--            (excludes defekt and wartung).
--            Grundlage für den Verfügbarkeitskalender im Frontend.
--            Temporale Verfügbarkeit wird durch fn_ist_item_verfuegbar
--            auf Anwendungsebene geprüft.
-- ============================================================
CREATE VIEW view_verfuegbarkeit AS 
SELECT
    gt.geraetetyp_bezeichnung,
    gm.geraet_modell_id,
    gm.geraet_bezeichnung,
    gi.geraet_item_id,
    gi.geraete_nr,
    gi.item_zustand,
    gt.preis_pro_tag,
    gt.lieferpreis
FROM geraet_item gi
JOIN geraet_modell gm ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN geraetetyp gt    ON gm.geraetetyp_id    = gt.geraetetyp_id
WHERE gi.item_zustand NOT IN ('defekt', 'wartung');

-- ============================================================
-- VIEW:      view_aktive_reservierungen
-- ZWECK:     Zeigt alle Reservierungen deren Mietzeitraum
--            das heutige Datum einschliesst.
--            Gibt dem Administrator einen Überblick über
--            alle aktuell ausgeliehenen Geräte.
-- ============================================================
CREATE VIEW view_aktive_reservierungen AS
SELECT
    r.reservierung_nr,
    r.datum AS buchungsdatum, -- Non-ambiguity
    k.kunden_nr,
    k.nachname,
    k.vorname,
    k.telefon,
    gm.geraet_bezeichnung,
    gi.geraete_nr,
    gi.sn_nr,
    rp.von_datum,
    rp.bis_datum,
    a.strasse,
    a.haus_nr,
    a.plz,
    a.ort
FROM reservierung r
JOIN kunde k                  ON r.kunde_id          = k.kunde_id
JOIN reservierungsposition rp ON r.reservierung_id   = rp.reservierung_id
JOIN geraet_item gi           ON rp.geraet_item_id   = gi.geraet_item_id
JOIN geraet_modell gm         ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN adresse a                ON r.adresse_id        = a.adresse_id
WHERE rp.von_datum <= CURDATE()
  AND rp.bis_datum >= CURDATE();

-- ============================================================
-- VIEW:      view_rueckgaben_heute
-- ZWECK:     Zeigt alle Geräte die heute zurückgegeben werden.
--            Ermöglicht dem Lager die Vorbereitung
--            für den Geräterücknahme.
-- ============================================================
CREATE VIEW view_rueckgaben_heute AS
SELECT
    r.reservierung_nr,
    k.kunden_nr,
    k.nachname,
    k.vorname,
    k.telefon,
    gm.geraet_bezeichnung,
    gi.geraete_nr,
    gi.sn_nr,
    gi.item_zustand,
    rp.von_datum,
    rp.bis_datum,
    a.strasse,
    a.haus_nr,
    a.plz,
    a.ort
FROM reservierung r
JOIN kunde k                  ON r.kunde_id          = k.kunde_id
JOIN reservierungsposition rp ON r.reservierung_id   = rp.reservierung_id
JOIN geraet_item gi           ON rp.geraet_item_id   = gi.geraet_item_id
JOIN geraet_modell gm         ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN adresse a                ON r.adresse_id        = a.adresse_id
WHERE rp.bis_datum = CURDATE();

-- ============================================================
-- VIEW:      view_geraet_status
-- ZWECK:     Zeigt den aktuellen physischen Zustand
--            aller Geräte gruppiert nach Modell.
--            Gibt dem Lager einen vollständigen Überblick
--            über den Bestand.
-- ============================================================
CREATE VIEW view_geraet_status AS
SELECT
    gt.geraetetyp_bezeichnung,
    gm.geraet_bezeichnung,
    gi.geraet_item_id,
    gi.geraete_nr,
    gi.sn_nr,
    gi.item_zustand,
    gi.anschaffungsdatum
FROM geraet_item gi
JOIN geraet_modell gm ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN geraetetyp gt    ON gm.geraetetyp_id    = gt.geraetetyp_id
ORDER BY gt.geraetetyp_bezeichnung, gm.geraet_bezeichnung, gi.item_zustand;

-- ============================================================
-- VIEW:      view_kunde_reservierungen
-- ZWECK:     Zeigt alle Reservierungen eines Kunden
--            mit vollständigen Details.
--            Grundlage für das Kundenprofil im Frontend.
-- ============================================================
CREATE VIEW view_kunde_reservierungen AS
SELECT
    k.kunden_nr,
    k.nachname,
    k.vorname,
    k.email,
    r.reservierung_nr,
    r.datum AS buchungsdatum,
    gm.geraet_bezeichnung,
    gt.geraetetyp_bezeichnung,
    gi.geraete_nr,
    rp.reservierungsposition_nr,
    rp.von_datum,
    rp.bis_datum,
    rp.pos_preis_pro_tag,
    rp.pos_lieferpreis,
    fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag,
        rp.pos_lieferpreis
    ) AS pos_gesamt,
    a.strasse,
    a.haus_nr,
    a.plz,
    a.ort
FROM kunde k
JOIN reservierung r            ON k.kunde_id          = r.kunde_id
JOIN reservierungsposition rp  ON r.reservierung_id   = rp.reservierung_id
JOIN geraet_item gi            ON rp.geraet_item_id   = gi.geraet_item_id
JOIN geraet_modell gm          ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN geraetetyp gt             ON gm.geraetetyp_id    = gt.geraetetyp_id
JOIN adresse a                 ON r.adresse_id        = a.adresse_id
ORDER BY k.kunden_nr, r.datum DESC;

-- ============================================================
-- REPORTING VIEWS
-- ============================================================

-- ============================================================
-- VIEW:      view_umsatz_monatlich
-- ZWECK:     Zeigt den monatlichen Umsatz gruppiert nach Monat.
--            Grundlage für die Umsatzübersicht im Dashboard.
-- VERWENDET: fn_calc_pos_gesamt
-- ============================================================
CREATE VIEW view_umsatz_monatlich AS
SELECT
    YEAR(rp.von_datum)  AS jahr,
    MONTH(rp.von_datum) AS monat,
    COUNT(DISTINCT r.reservierung_id)  AS anzahl_reservierungen,
    COUNT(rp.reservierungsposition_id) AS anzahl_positionen,
    SUM(fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag,
        rp.pos_lieferpreis
    )) AS umsatz_gesamt
FROM reservierungsposition rp
JOIN reservierung r ON rp.reservierung_id = r.reservierung_id
GROUP BY YEAR(rp.von_datum), MONTH(rp.von_datum)
ORDER BY jahr DESC, monat DESC;

-- ============================================================
-- VIEW:      view_umsatz_pro_kunde
-- ZWECK:     Zeigt den Gesamtumsatz pro Kunde.
--            Grundlage für die Kundenanalyse im Dashboard.
-- VERWENDET: fn_calc_pos_gesamt
-- ============================================================
CREATE VIEW view_umsatz_pro_kunde AS
SELECT
    k.kunden_nr,
    k.nachname,
    k.vorname,
    k.email,
    COUNT(DISTINCT r.reservierung_id)  AS anzahl_reservierungen,
    COUNT(rp.reservierungsposition_id) AS anzahl_positionen,
    SUM(fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag,
        rp.pos_lieferpreis
    )) AS umsatz_gesamt
FROM kunde k
JOIN reservierung r           ON k.kunde_id        = r.kunde_id
JOIN reservierungsposition rp ON r.reservierung_id = rp.reservierung_id
GROUP BY k.kunde_id, k.kunden_nr, k.nachname, k.vorname, k.email
ORDER BY umsatz_gesamt DESC;

-- ============================================================
-- VIEW:      view_umsatz_pro_kategorie
-- ZWECK:     Zeigt den Gesamtumsatz pro Gerätekategorie.
--            Hilft bei der Entscheidung welche Kategorien
--            am profitabelsten sind.
-- VERWENDET: fn_calc_pos_gesamt
-- ============================================================
CREATE VIEW view_umsatz_pro_kategorie AS
SELECT
    gt.geraetetyp_bezeichnung,
    COUNT(DISTINCT gm.geraet_modell_id)        AS anzahl_modelle,
    COUNT(DISTINCT gi.geraet_item_id)          AS anzahl_items,
    COUNT(DISTINCT r.reservierung_id)          AS anzahl_reservierungen,
    COUNT(rp.reservierungsposition_id)         AS anzahl_positionen,
    SUM(fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag,
        rp.pos_lieferpreis
    )) AS umsatz_gesamt
FROM geraetetyp gt
JOIN geraet_modell gm         ON gt.geraetetyp_id    = gm.geraetetyp_id
JOIN geraet_item gi           ON gm.geraet_modell_id = gi.geraet_modell_id
JOIN reservierungsposition rp ON gi.geraet_item_id   = rp.geraet_item_id
JOIN reservierung r           ON rp.reservierung_id  = r.reservierung_id
GROUP BY gt.geraetetyp_id, gt.geraetetyp_bezeichnung
ORDER BY umsatz_gesamt DESC;

-- ============================================================
-- ANALYTICAL VIEWS
-- ============================================================

-- ============================================================
-- VIEW:      view_geraet_auslastung
-- ZWECK:     Zeigt wie oft und wie lange jedes Gerät
--            vermietet wurde. Grundlage für Entscheidungen
--            über Ankauf und Aussonderung von Geräten.
-- VERWENDET: fn_calc_tage
-- ============================================================
CREATE VIEW view_geraet_auslastung AS
SELECT
    gt.geraetetyp_bezeichnung,
    gm.geraet_bezeichnung,
    gi.geraete_nr,
    gi.sn_nr,
    gi.anschaffungsdatum,
    gi.item_zustand,
    COUNT(rp.reservierungsposition_id) AS anzahl_vermietungen,
    COALESCE(SUM(fn_calc_tage(
        rp.von_datum,
        rp.bis_datum
    )), 0) AS tage_gesamt
FROM geraet_item gi
JOIN geraet_modell gm          ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN geraetetyp gt             ON gm.geraetetyp_id    = gt.geraetetyp_id
LEFT JOIN reservierungsposition rp ON gi.geraet_item_id = rp.geraet_item_id
GROUP BY
    gt.geraetetyp_bezeichnung,
    gm.geraet_bezeichnung,
    gi.geraet_item_id,
    gi.geraete_nr,
    gi.sn_nr,
    gi.anschaffungsdatum,
    gi.item_zustand
ORDER BY tage_gesamt DESC;

-- ============================================================
-- SECURITY VIEWS
-- ============================================================

-- ============================================================
-- VIEW:      view_secure_kunde
-- ZWECK:     Maskiert persönliche Kundendaten für Analysten.
--            Gibt genug Information für Reports ohne
--            Rückschlüsse auf die Identität zu ermöglichen.
--            DSGVO-konform (Art. 5 & 25 — Privacy by Design)
-- ============================================================
CREATE VIEW view_secure_kunde AS
SELECT
    kunde_id,
    kunden_nr,
    LEFT(nachname, 1)                    AS nachname_initial,
    LEFT(vorname, 1)                     AS vorname_initial,
    LEFT(email, 3)                       AS email_masked,
    CHAR_LENGTH(telefon)                 AS telefon_laenge,
    adresse_id
FROM kunde;

-- ============================================================
-- VIEW:      view_secure_adresse
-- ZWECK:     Maskiert Adressdaten für Analysten.
--            PLZ und Ort bleiben sichtbar für regionale
--            Auswertungen — Strasse und Hausnummer werden
--            ausgeblendet.
--            DSGVO-konform (Art. 5 & 25 — Privacy by Design)
-- ============================================================
CREATE VIEW view_secure_adresse AS
SELECT
    adresse_id,
    '***'    AS strasse,
    '***'    AS haus_nr,
    NULL     AS adresse_zusatz,
    plz,
    ort
FROM adresse;