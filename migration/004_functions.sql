/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:    004_functions.sql
-- PROJEKT:   Reservierung DB
-- ZIELSETZUNG: Gespeicherte Funktionen für wiederkehrende
--             Berechnungen und Verfügbarkeitsprüfungen
-- ============================================================

USE reservierung_db;

DELIMITER //

-- ============================================================
-- FUNKTION:  fn_calc_tage
-- ZWECK:     Berechnet die Anzahl der Miettage zwischen
--            zwei Datumsangaben (inklusive Starttag)
--
-- PARAMETER:
--   p_von DATE → Startdatum der Reservierung
--   p_bis DATE → Enddatum der Reservierung
--
-- RÜCKGABE:  INT → Anzahl der Miettage
--
-- BEISPIEL:
--   SELECT fn_calc_tage('2026-05-01', '2026-05-05');
--   → Ergebnis: 4 (01., 02., 03., 04. Mai — der 05. ist Rückgabetag)
--
-- HINWEIS:
--   DATEDIFF(bis, von) berechnet die Differenz in Tagen.
--   Mathematisch: 05.05 - 01.05 = 4 Tage.
--   Der Rückgabetag wird nicht als Miettag gezählt —
--   analog zu Hotelübernachtungen (Check-in / Check-out).
-- ============================================================
CREATE FUNCTION fn_calc_tage(
    p_von DATE,
    p_bis DATE
)
RETURNS INT
DETERMINISTIC -- gleiche Daten - immer gleiche Anzahl Tage
COMMENT 'Berechnet die Anzahl der Miettage zwischen zwei Datumsangaben'
BEGIN
    -- Sicherheitsprüfung: Enddatum darf nicht vor Startdatum liegen.
    -- Dies wird zwar bereits durch den CHECK-Constraint in der Tabelle
    -- verhindert, hier dient es als zusätzliche Absicherung auf
    -- Funktionsebene (Tiefenverteidigung).
    IF p_bis < p_von THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Enddatum darf nicht vor dem Startdatum liegen.';
    END IF;

    RETURN DATEDIFF(p_bis, p_von);
END //


-- ============================================================
-- FUNKTION:  fn_calc_pos_gesamt
-- ZWECK:     Berechnet den Gesamtpreis einer Reservierungsposition.
--            Der Gesamtpreis setzt sich zusammen aus:
--            (Anzahl Miettage × Preis pro Tag) + Lieferpreis
--
-- PARAMETER:
--   p_von          DATE         → Startdatum
--   p_bis          DATE         → Enddatum
--   p_preis_pro_tag DECIMAL     → Tagespreis des Gerätetyps
--   p_lieferpreis  DECIMAL      → Lieferpreis des Gerätetyps
--
-- RÜCKGABE:  DECIMAL(10,2) → Gesamtbetrag in Euro
--
-- BEISPIEL:
--   SELECT fn_calc_pos_gesamt('2026-05-01', '2026-05-05', 25.00, 10.00);
--   → 4 Tage × 25.00 + 10.00 = 110.00 €
--
-- HINWEIS:
--   Diese Funktion ruft intern fn_calc_tage auf, dadurch wird
--   die Berechnungslogik nicht dupliziert (DRY-Prinzip)
--   Änderungen an der Tagesberechnung
--   müssen nur an einer einzigen Stelle vorgenommen werden.
-- ============================================================
CREATE FUNCTION fn_calc_pos_gesamt(
    p_von           DATE,
    p_bis           DATE,
    p_preis_pro_tag DECIMAL(10,2),
    p_lieferpreis   DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC -- gleiche Preise und Daten → immer gleicher Betrag
COMMENT 'Berechnet den Gesamtpreis einer Position: (Tage × Tagespreis) + Lieferpreis'
BEGIN
    -- Lokale Variable für die Anzahl der Miettage
    DECLARE v_tage INT;

    -- Wiederverwendung von fn_calc_tage (DRY-Prinzip)
    SET v_tage = fn_calc_tage(p_von, p_bis);

    -- Gesamtpreis: Mietkosten + einmaliger Lieferpreis
    RETURN (v_tage * p_preis_pro_tag) + p_lieferpreis;
END //


-- ============================================================
-- FUNKTION:  fn_ist_item_verfuegbar
-- ZWECK:     Prüft ob ein konkretes Gerät (Item) für einen
--            gewünschten Zeitraum verfügbar ist.
--
--            Ein Item gilt als NICHT verfügbar wenn:
--            1. Sein physischer Zustand 'defekt' oder 'wartung' ist
--            2. Es im gewünschten Zeitraum bereits reserviert ist
--               (Überschneidungslogik / Overlap-Prüfung)
--
-- PARAMETER:
--   p_item_id INT  → ID des zu prüfenden Geräts (geraet_item_id)
--   p_von     DATE → Gewünschtes Startdatum
--   p_bis     DATE → Gewünschtes Enddatum
--
-- RÜCKGABE:  TINYINT(1) → 1 = verfügbar / 0 = nicht verfügbar
--            (MySQL kennt keinen nativen BOOLEAN-Typ,
--             TINYINT(1) ist die standardkonforme Alternative)
--
-- ÜBERSCHNEIDUNGSLOGIK (Overlap-Check):
--   Zwei Zeiträume überschneiden sich wenn:
--   bestehende Reservierung beginnt VOR Ende der neuen Anfrage
--   UND bestehende Reservierung endet NACH Beginn der neuen Anfrage
--
--   Visuell:
--   Bestehend:  |------A------|
--   Konflikt:         |------B------|  → B beginnt vor Ende von A
--   Kein Konflikt:                |--C--|  → C beginnt nach Ende von A
--
--   SQL-Bedingung: rp.von_datum <= p_bis AND rp.bis_datum >= p_von
--
-- VERWENDUNG:
--   Diese Funktion wird von Triggern und Views verwendet
--   um die Verfügbarkeitsprüfung zentral zu halten.
--
-- BEISPIEL:
--   SELECT fn_ist_item_verfuegbar(1, '2026-07-01', '2026-07-05');
--   → 1 (verfügbar) oder 0 (nicht verfügbar)
-- ============================================================
CREATE FUNCTION fn_ist_item_verfuegbar(
    p_item_id INT,
    p_von     DATE,
    p_bis     DATE
)
RETURNS TINYINT   -- TINYINT(1) deprektiert, ab v8.0.19
NOT DETERMINISTIC -- Ergebnis hängt vom aktuellen Datenbankinhalt ab
                  -- dieselbe Anfrage kann morgen ein anderes Ergebnis
                  -- liefern wenn zwischenzeitlich eine neue Reservierung
                  -- eingetragen wurde
READS SQL DATA    -- deklariert dass die Funktion nur liest (kein INSERT/UPDATE)
                  -- ermöglicht MySQL interne Optimierungen
COMMENT 'Gibt 1 zurück wenn das Item im Zeitraum verfügbar ist, sonst 0'
BEGIN
    DECLARE v_anzahl_konflikte INT;

    -- Zählt alle Reservierungspositionen die sich mit dem
    -- gewünschten Zeitraum überschneiden UND zum selben Item gehören.
    -- Zusätzlich wird der physische Zustand geprüft:
    -- defekte oder gewartete Geräte gelten als nicht verfügbar
    -- unabhängig von bestehenden Reservierungen.
    SELECT COUNT(*) INTO v_anzahl_konflikte
    FROM geraet_item gi
    LEFT JOIN reservierungsposition rp
          ON gi.geraet_item_id  = rp.geraet_item_id
          AND rp.von_datum      <= p_bis   -- Überschneidung: Beginn vor Ende der Anfrage
          AND rp.bis_datum      >= p_von   -- Überschneidung: Ende nach Beginn der Anfrage
    WHERE gi.geraet_item_id = p_item_id
      AND (
            gi.item_zustand IN ('defekt', 'wartung') -- physisch nicht verfügbar
            OR rp.reservierungsposition_id IS NOT NULL -- zeitlich belegt
          );

    -- Wenn keine Konflikte gefunden wurden → verfügbar (1)
    -- Wenn mindestens ein Konflikt gefunden wurde → nicht verfügbar (0)
    RETURN IF(v_anzahl_konflikte = 0, 1, 0);
END //

DELIMITER ;