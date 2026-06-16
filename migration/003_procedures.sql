/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SCRIPT:        003_procedures.sql
-- PROJEkT:       Reservierung DB
-- ZIELSETZUNG:   Gespeicherte Prozeduren (Stored Procedures) für die Businesslogik
-- ============================================================

USE reservierung_db;
/*!40101 SET NAMES utf8mb4 */;

DELIMITER //
-- ============================================================
-- PROZEDUR:     pro_adresse_suchen_oder_anlegen
-- BESCHREIBUNG: Sucht nach einer Adresse basierend auf den übergebenen Parametern.
--               Wenn keine passende Adresse gefunden wird, wird eine neue Adresse angelegt und deren ID zurückgegeben.
--               Wird intern von anderen Prozeduren verwendet, um Datenredundanz zu vermeiden.
-- ============================================================
CREATE PROCEDURE pro_adresse_suchen_oder_anlegen(
    IN p_strasse VARCHAR(100),
    IN p_haus_nr VARCHAR(10),
    IN p_zusatz VARCHAR(20), 
    IN p_plz VARCHAR(10),
    IN p_ort VARCHAR(100),
    OUT p_adr_id INT
)
BEGIN
    SET p_adr_id = NULL;

    -- In "adresse_zusatz" NULL-Werte sind über den Operator <=> erlaubt
    SELECT adresse_id INTO p_adr_id 
    FROM adresse 
    WHERE strasse = p_strasse 
      AND haus_nr = p_haus_nr 
      AND adresse_zusatz <=> p_zusatz
      AND plz = p_plz 
      AND ort = p_ort
    LIMIT 1;

    -- Wenn keine, "nur dann", Adresse einlegen 
    IF p_adr_id IS NULL THEN
        INSERT INTO adresse (
          strasse,
          haus_nr,
          adresse_zusatz,
          plz,
          ort
        )
        VALUES (
          p_strasse,
          p_haus_nr,
          p_zusatz,
          p_plz,
          p_ort);
        
        SET p_adr_id = LAST_INSERT_ID();
    END IF;
END //

-- ============================================================
-- PROZEDUR:    pro_kunde_mit_adresse_anlegen
-- BESCHREIBUNG: Erstellt ein Kundenprofil. Ruft zuerst die Adress-Prozedur auf.
-- ============================================================
CREATE PROCEDURE pro_kunde_mit_adresse_anlegen(
    -- Kundendaten
    IN p_kunden_nr VARCHAR(20),
    IN p_nname VARCHAR(100),
    IN p_vname VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefon VARCHAR(20),
    -- Adressdaten
    IN p_strasse VARCHAR(100),
    IN p_haus_nr VARCHAR(10),
    IN p_zusatz VARCHAR(20),
    IN p_plz VARCHAR(10),
    IN p_ort VARCHAR(100)
)
BEGIN
    -- Lokale Variable für die Adress-ID 
    DECLARE v_adr_id INT;

    -- Rollback-Behandlung wann notig: Atomare Transaktion (ACID-Prinzipien)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK; 
        -- Fehler weiterreichen über die Datenbankschnittstelle an den aufrufenden Client
        -- (sei es die CLI, eine GUI wie MySQL Workbench oder eine Backend-Applikation)
        RESIGNAL;
    END;

    START TRANSACTION;
        -- 1. Prozeduraufruf: Nach bestehender Adresse suchen oder eine neue anlegen
        CALL pro_adresse_suchen_oder_anlegen(
          p_strasse, p_haus_nr, p_zusatz, p_plz, p_ort, v_adr_id
        );

        -- 2. Kundenbeleg unter Verwendung der abgerufenen Adress-ID erstellen
        INSERT INTO kunde (kunden_nr, nachname, vorname, email, telefon, adresse_id)
        VALUES (p_kunden_nr, p_nname, p_vname, p_email, p_telefon, v_adr_id);
    COMMIT;
END //

-- ============================================================
-- PROZEDUR:     pro_reservierung_erstellen
-- BESCHREIBUNG: Hauptprozedur für Buchungen. Findet ein verfügbares physisches Exemplar,
--               erstellt die Reservierung und aktualisiert den logistischen Zustand im Bestand.
-- ============================================================
CREATE PROCEDURE pro_reservierung_erstellen(
    IN p_kunde_id INT,
    IN p_geraet_modell_id INT,
    IN p_von_datum DATE,
    IN p_bis_datum DATE,
    IN p_res_nr VARCHAR(20),
    IN p_pos_nr INT,
    -- Mögliche Lieferadresse (derzeit nicht verwendet) – Skalierbarkeit
    IN p_l_strasse VARCHAR(100),
    IN p_l_haus_nr VARCHAR(10),
    IN p_l_zusatz VARCHAR(20),
    IN p_l_plz VARCHAR(10),
    IN p_l_ort VARCHAR(100)
)
BEGIN
    DECLARE v_l_adr_id INT;
    DECLARE v_res_id INT;
    DECLARE v_tagespreis DECIMAL(10,2); 
    DECLARE v_lieferpreis DECIMAL(10,2);
    DECLARE v_gewaehltes_item_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validierung: Startdatum darf nicht in der Vergangenheit liegen - erste niveau.
    IF p_von_datum < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Das startdatum darf nicht in der Vergangenheit sein.';
    END IF;

    -- Isolationsstufe (ACID-Prinzip)
    START TRANSACTION;
        -- 1. Preisermittlung basierend auf der Gerätekategorie
        -- Implementierung von pessimistischem Sperren (SELECT ... FOR UPDATE)
        SELECT gi.geraet_item_id, gt.preis_pro_tag, gt.lieferpreis 
        INTO v_gewaehltes_item_id, v_tagespreis, v_lieferpreis 
        FROM geraet_item gi
        JOIN geraet_modell gm ON gi.geraet_modell_id = gm.geraet_modell_id
        JOIN geraetetyp gt ON gm.geraetetyp_id = gt.geraetetyp_id
        WHERE gi.geraet_modell_id = p_geraet_modell_id
          -- Physische Verfügbarkeitsprüfung
          AND gi.item_zustand NOT IN ('defekt', 'wartung')
          -- Zeitliche Überschneidungsprüfung
          AND gi.geraet_item_id NOT IN (
            SELECT rp.geraet_item_id
            FROM reservierungsposition rp
            -- Validierungslogik für Überschneidungen (Overlap)
            WHERE rp.von_datum <= p_bis_datum
              AND rp.bis_datum >= p_von_datum
          )
        LIMIT 1
        -- Sperre auf Zeilenebene / Row-Level-Lock (Nebenläufigkeitstheorie)
        FOR UPDATE;

        -- Eine erste Schutzstufe, um Doppelbuchungen zu vermeiden
        IF v_gewaehltes_item_id IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Kein verfügbares Exemplar für dieses Modell gefunden.';
        END IF;

        -- 3. Prozeduraufruf: Lieferadresse suchen oder anlegen
        CALL pro_adresse_suchen_oder_anlegen(
          p_l_strasse,
          p_l_haus_nr, p_l_zusatz, p_l_plz, p_l_ort, v_l_adr_id);

        -- 4. Reservierungsdatensatz einfügen
        INSERT INTO reservierung (reservierung_nr, datum, adresse_id, kunde_id)
        VALUES (p_res_nr, NOW(), v_l_adr_id, p_kunde_id);
        
        SET v_res_id = LAST_INSERT_ID();

        -- 5. Position der Reservierungszeile einfügen
        INSERT INTO reservierungsposition (
            reservierungsposition_nr, pos_preis_pro_tag, pos_lieferpreis, 
            von_datum, bis_datum, geraet_item_id, reservierung_id
        )
        VALUES (
            p_pos_nr, v_tagespreis, v_lieferpreis, 
            p_von_datum, p_bis_datum, v_gewaehltes_item_id, v_res_id
        );
    COMMIT;
END //

DELIMITER ;