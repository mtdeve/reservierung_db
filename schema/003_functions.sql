/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

USE reservierung_db;

DELIMITER //

CREATE FUNCTION fn_calc_tage(
    p_von DATE,
    p_bis DATE
)
RETURNS INT
DETERMINISTIC
COMMENT 'Berechnet die Anzahl der Miettage zwischen zwei Datumsangaben'
BEGIN
    IF p_bis < p_von THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Enddatum darf nicht vor dem Startdatum liegen.';
    END IF;

    RETURN DATEDIFF(p_bis, p_von);
END //

CREATE FUNCTION fn_calc_pos_gesamt(
    p_von           DATE,
    p_bis           DATE,
    p_preis_pro_tag DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
COMMENT 'Gesamtpreis einer Position: Tage * Tagespreis'
BEGIN
    -- Lokale Variable für die Anzahl der Miettage
    DECLARE v_tage INT;

    -- Wiederverwendung von fn_calc_tage (DRY-Prinzip)
    SET v_tage = fn_calc_tage(p_von, p_bis);

    -- Gesamtpreis
    RETURN (v_tage * p_preis_pro_tag);
END //


CREATE FUNCTION fn_ist_item_verfuegbar(
    p_item_id INT,
    p_von     DATE,
    p_bis     DATE
)
-- TINYINT(1) deprektiert, ab v8.0.19
RETURNS TINYINT  
NOT DETERMINISTIC
-- deklariert dass die Funktion nur liest (kein INSERT/UPDATE)
-- ermöglicht MySQL interne Optimierungen (Ausführung und Query Cache)
READS SQL DATA
COMMENT '1 = verfügbar, 0 = nicht verfügbar'
BEGIN
    DECLARE v_anzahl_konflikte INT;
    SELECT COUNT(*) INTO v_anzahl_konflikte
    FROM geraet_item gi
    LEFT JOIN position rp
          ON gi.geraet_item_id  = rp.geraet_item_id
          AND rp.von_datum      <= p_bis
          AND rp.bis_datum      >= p_von
    WHERE gi.geraet_item_id = p_item_id
      -- physisch nicht verfügbar und zeitlich belegt
      AND (
            gi.item_zustand IN ('defekt', 'wartung')
            OR rp.position_id IS NOT NULL
          );

    -- Wenn keine Konflikte → verfügbar (1)
    -- Wenn mindestens ein Konflikt → nicht verfügbar (0)
    RETURN IF(v_anzahl_konflikte = 0, 1, 0);
END //

DELIMITER ;