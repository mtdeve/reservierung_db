/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:    005_views.sql
-- PROJEKT:   Reservierung DB
-- ZIELSETZUNG: Views für verschiedene Anwendungsfälle
-- ============================================================

USE reservierung_db;

-- ============================================================
-- OPERATIONAL VIEWS
-- ============================================================

-- ============================================================
-- VIEW:      view_verfuegbarkeit
-- ZWECK:     Zeigt für jedes Gerätemodell und jeden Zeitraum
--            ob ein konkretes Exemplar verfügbar ist.
--            Grundlage für den Verfügbarkeitskalender im Frontend.
-- VERWENDET: fn_ist_item_verfuegbar
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


CREATE VIEW view_rueckgaben_heute ...
CREATE VIEW view_geraet_status ...
CREATE VIEW view_kunde_reservierungen ...

-- ============================================================
-- REPORTING VIEWS
-- ============================================================

CREATE VIEW view_umsatz_monatlich ...
CREATE VIEW view_umsatz_pro_kunde ...
CREATE VIEW view_umsatz_pro_kategorie ...

-- ============================================================
-- ANALYTICAL VIEWS
-- ============================================================

CREATE VIEW view_geraet_auslastung ...

-- ============================================================
-- SECURITY VIEWS
-- ============================================================

CREATE VIEW view_secure_kunde ...
CREATE VIEW view_secure_adresse ...