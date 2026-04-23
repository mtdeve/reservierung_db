/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:    003_prozeduren.sql
-- PROJEKT:   Reservierung DB
-- ZIELSETZUNG: Gespeicherte Prozeduren für die Geschäftslogik
-- ============================================================

USE reservierung_db;

DELIMITER //
-- PROZEDUR:    pro_adresse_suchen_oder_anlegen
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

    SELECT adresse_id INTO p_adr_id 
    FROM adresse 
    WHERE strasse = p_strasse 
      AND haus_nr = p_haus_nr 
      AND adresse_zusatz <=> p_zusatz -- NULLABLE ist Ok
      AND plz = p_plz 
      AND ort = p_ort
    LIMIT 1;

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
END
//

-- PROZEDUR:    pro_kunde_mit_adresse_anlegen
-- ============================================================
CREATE PROCEDURE pro_kunde_mit_adresse_anlegen(
    -- Kundendaten
    IN p_kunden_nr VARCHAR(20),
    IN p_nname VARCHAR(100),
    IN p_vname VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefon VARCHAR(20),
    -- Addressdaten
    IN p_strasse VARCHAR(100),
    IN p_haus_nr VARCHAR(10),
    IN p_zusatz VARCHAR(20),
    IN p_plz VARCHAR(10),
    IN p_ort VARCHAR(100)
)
BEGIN
    DECLARE v_adr_id INT; -- Lokale Variable für die Adresse-ID

    -- Atomare Transaktion:(ACID-Prinzip)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        -- 1. Prozedeuraufruf: Adresse suchen oder anlegen
        CALL pro_adresse_suchen_oder_anlegen(
          p_strasse, p_haus_nr, p_zusatz, p_plz, p_ort, v_adr_id
        );

        -- 2. Anlegen des Kunden mit der erhaltenen Adresse-ID
        INSERT INTO kunde (kunden_nr, nachname, vorname, email, telefon, adresse_id)
        VALUES (p_kunden_nr, p_nname, p_vname, p_email, p_telefon, v_adr_id);
    COMMIT;
END
//

-- PROZEDUR:    pro_reservierung_erstellen
-- ============================================================
CREATE PROCEDURE pro_reservierung_erstellen(
    IN p_kunde_id INT,
    IN p_geraet_modell_id INT,
    IN p_von_datum DATE,
    IN p_bis_datum DATE,
    IN p_res_nr VARCHAR(20),
    IN p_pos_nr INT,
    -- Lieferadresse
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

    -- Rollback: Atomare Transaktion (ACID-Prinzip)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;


    START TRANSACTION; -- Isolation (ACID-Prinzip)
        -- 1. Preisermittlung basierend auf Gerätetyp
        -- Pessimistische Sperrung (SELECT ... FOR UPDATE)
        SELECT gi.geraet_item_id, gt.preis_pro_tag, gt.lieferpreis 
        INTO v_gewaehltes_item_id, v_tagespreis, v_lieferpreis 
        FROM geraet_item gi
        JOIN geraet_modell gm ON gi.geraet_modell_id = gm.geraet_modell_id
        JOIN geraetetyp gt ON gm.geraetetyp_id = gt.geraetetyp_id
        WHERE gi.geraet_modell_id = p_geraet_modell_id 
          AND gi.item_zustand NOT IN ('defekt', 'wartung')  -- stato fisico
          AND gi.geraet_item_id NOT IN (                    -- disponibilità temporale
            SELECT rp.geraet_item_id
            FROM reservierungsposition rp
            WHERE rp.von_datum <= p_bis_datum              -- overlap check
              AND rp.bis_datum >= p_von_datum
          )
        LIMIT 1
        FOR UPDATE; -- Sperrt (Nebenläufigkeitstheorie)

        -- 2. Sicherheit: Falls kein Exemplar verfügbar ist, Abbruch der Prozedur.
        IF v_gewaehltes_item_id IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Kein verfügbares Exemplar für dieses Modell gefunden.';
        END IF;
        -- 3. Prozedeuraufruf: Lieferadresse suchen oder anlegen
        CALL pro_adresse_suchen_oder_anlegen(
          p_l_strasse,
          p_l_haus_nr, p_l_zusatz, p_l_plz, p_l_ort, v_l_adr_id);

        -- 4. Reservierung anlegen
        INSERT INTO reservierung (reservierung_nr, datum, adresse_id, kunde_id)
        VALUES (p_res_nr, NOW(), v_l_adr_id, p_kunde_id);
        
        SET v_res_id = LAST_INSERT_ID();

        -- 5. Position anlegen
        INSERT INTO reservierungsposition (
            reservierungsposition_nr, pos_preis_pro_tag, pos_lieferpreis, 
            von_datum, bis_datum, geraet_item_id, reservierung_id
        )
        VALUES (
            p_pos_nr, v_tagespreis, v_lieferpreis, 
            p_von_datum, p_bis_datum, v_gewaehltes_item_id, v_res_id
        );

        -- 6. Gerät als vermietet markieren (Zustandsänderung)
        UPDATE geraet_item 
        SET item_zustand = 'vermietet' 
        WHERE geraet_item_id = v_gewaehltes_item_id;
    COMMIT;
END
//

DELIMITER ;