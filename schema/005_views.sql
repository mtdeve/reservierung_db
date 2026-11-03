/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

USE reservierung_db;

-- OPERATIONAL VIEWS

CREATE VIEW view_verfuegbarkeit AS 
SELECT
    gt.geraetetyp_bezeichnung,
    gm.geraet_modell_id,
    gm.geraet_bezeichnung,
    gi.geraet_item_id,
    gi.geraete_nr,
    gi.item_zustand,
    gt.preis_pro_tag
FROM geraet_item gi
JOIN geraet_modell gm ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN geraetetyp gt    ON gm.geraetetyp_id    = gt.geraetetyp_id
WHERE gi.item_zustand NOT IN ('defekt', 'wartung');


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
JOIN position rp ON r.reservierung_id   = rp.reservierung_id
JOIN geraet_item gi           ON rp.geraet_item_id   = gi.geraet_item_id
JOIN geraet_modell gm         ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN adresse a                ON r.adresse_id        = a.adresse_id
WHERE rp.von_datum <= CURDATE()
  AND rp.bis_datum >= CURDATE();


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
JOIN position rp ON r.reservierung_id   = rp.reservierung_id
JOIN geraet_item gi           ON rp.geraet_item_id   = gi.geraet_item_id
JOIN geraet_modell gm         ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN adresse a                ON r.adresse_id        = a.adresse_id
WHERE rp.bis_datum = CURDATE();


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
    rp.position_nr,
    rp.von_datum,
    rp.bis_datum,
    rp.pos_preis_pro_tag,
    fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag
    ) AS pos_gesamt,
    a.strasse,
    a.haus_nr,
    a.plz,
    a.ort
FROM kunde k
JOIN reservierung r            ON k.kunde_id          = r.kunde_id
JOIN position rp  ON r.reservierung_id   = rp.reservierung_id
JOIN geraet_item gi            ON rp.geraet_item_id   = gi.geraet_item_id
JOIN geraet_modell gm          ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN geraetetyp gt             ON gm.geraetetyp_id    = gt.geraetetyp_id
JOIN adresse a                 ON r.adresse_id        = a.adresse_id
ORDER BY k.kunden_nr, r.datum DESC;

-- REPORTING VIEWS

CREATE VIEW view_umsatz_monatlich AS
SELECT
    YEAR(rp.von_datum)  AS jahr,
    MONTH(rp.von_datum) AS monat,
    COUNT(DISTINCT r.reservierung_id)  AS anzahl_reservierungen,
    COUNT(rp.position_id) AS anzahl_positionen,
    SUM(fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag
    )) AS umsatz_gesamt
FROM position rp
JOIN reservierung r ON rp.reservierung_id = r.reservierung_id
GROUP BY YEAR(rp.von_datum), MONTH(rp.von_datum)
ORDER BY jahr DESC, monat DESC;


CREATE VIEW view_umsatz_pro_kunde AS
SELECT
    k.kunden_nr,
    k.nachname,
    k.vorname,
    k.email,
    COUNT(DISTINCT r.reservierung_id)  AS anzahl_reservierungen,
    COUNT(rp.position_id) AS anzahl_positionen,
    SUM(fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag
    )) AS umsatz_gesamt
FROM kunde k
JOIN reservierung r           ON k.kunde_id        = r.kunde_id
JOIN position rp ON r.reservierung_id = rp.reservierung_id
GROUP BY k.kunde_id, k.kunden_nr, k.nachname, k.vorname, k.email
ORDER BY umsatz_gesamt DESC;


CREATE VIEW view_umsatz_pro_kategorie AS
SELECT
    gt.geraetetyp_bezeichnung,
    COUNT(DISTINCT gm.geraet_modell_id)        AS anzahl_modelle,
    COUNT(DISTINCT gi.geraet_item_id)          AS anzahl_items,
    COUNT(DISTINCT r.reservierung_id)          AS anzahl_reservierungen,
    COUNT(rp.position_id)         AS anzahl_positionen,
    SUM(fn_calc_pos_gesamt(
        rp.von_datum,
        rp.bis_datum,
        rp.pos_preis_pro_tag
    )) AS umsatz_gesamt
FROM geraetetyp gt
JOIN geraet_modell gm         ON gt.geraetetyp_id    = gm.geraetetyp_id
JOIN geraet_item gi           ON gm.geraet_modell_id = gi.geraet_modell_id
JOIN position rp ON gi.geraet_item_id   = rp.geraet_item_id
JOIN reservierung r           ON rp.reservierung_id  = r.reservierung_id
GROUP BY gt.geraetetyp_id, gt.geraetetyp_bezeichnung
ORDER BY umsatz_gesamt DESC;

-- ANALYTICAL VIEWS

CREATE VIEW view_geraet_auslastung AS
SELECT
    gt.geraetetyp_bezeichnung,
    gm.geraet_bezeichnung,
    gi.geraete_nr,
    gi.sn_nr,
    gi.anschaffungsdatum,
    gi.item_zustand,
    COUNT(rp.position_id) AS anzahl_vermietungen,
    COALESCE(SUM(fn_calc_tage(
        rp.von_datum,
        rp.bis_datum
    )), 0) AS tage_gesamt
FROM geraet_item gi
JOIN geraet_modell gm          ON gi.geraet_modell_id = gm.geraet_modell_id
JOIN geraetetyp gt             ON gm.geraetetyp_id    = gt.geraetetyp_id
LEFT JOIN position rp ON gi.geraet_item_id = rp.geraet_item_id
GROUP BY
    gt.geraetetyp_bezeichnung,
    gm.geraet_bezeichnung,
    gi.geraet_item_id,
    gi.geraete_nr,
    gi.sn_nr,
    gi.anschaffungsdatum,
    gi.item_zustand
ORDER BY tage_gesamt DESC;

-- SECURITY VIEWS

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


CREATE VIEW view_secure_adresse AS
SELECT
    adresse_id,
    '***'    AS strasse,
    '***'    AS haus_nr,
    NULL     AS adresse_zusatz,
    plz,
    ort
FROM adresse;