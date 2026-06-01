/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SCRIPT:      003_prozeduren.sql
-- PROJECT:     Reservierung DB
-- OBJECTIVE:   Stored procedures for business logic
-- ============================================================

USE reservierung_db;
/*!40101 SET NAMES utf8mb4 */;

DELIMITER //
-- ============================================================
-- PROCEDURE:   pro_adresse_suchen_oder_anlegen
-- DESCRIPTION: Searches for an address based on the provided parameters.
-- If no matching address is found, a new address is created and its ID is returned.
-- Used internally by other procedures to avoid data redundancy.
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
      AND adresse_zusatz <=> p_zusatz -- NULLABLE is OK
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

-- ============================================================
-- PROCEDURE:   pro_kunde_mit_adresse_anlegen
-- DESCRIPTION: Creates a customer profile. Calls the address procedure first.
-- Atomic transaction handling adhering to ACID principles.
-- ============================================================
CREATE PROCEDURE pro_kunde_mit_adresse_anlegen(
    -- Customer data
    IN p_kunden_nr VARCHAR(20),
    IN p_nname VARCHAR(100),
    IN p_vname VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefon VARCHAR(20),
    -- Address data
    IN p_strasse VARCHAR(100),
    IN p_haus_nr VARCHAR(10),
    IN p_zusatz VARCHAR(20),
    IN p_plz VARCHAR(10),
    IN p_ort VARCHAR(100)
)
BEGIN
    DECLARE v_adr_id INT; -- Local variable for the address ID

    -- Atomic Transaction handling (ACID principles)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK; 
        RESIGNAL;
    END;

    START TRANSACTION;
        -- 1. Procedure call: Search for existing address or create a new one
        CALL pro_adresse_suchen_oder_anlegen(
          p_strasse, p_haus_nr, p_zusatz, p_plz, p_ort, v_adr_id
        );

        -- 2. Create the customer record using the retrieved address ID
        INSERT INTO kunde (kunden_nr, nachname, vorname, email, telefon, adresse_id)
        VALUES (p_kunden_nr, p_nname, p_vname, p_email, p_telefon, v_adr_id);
    COMMIT;
END
//

-- ============================================================
-- PROCEDURE:   pro_reservierung_erstellen
-- DESCRIPTION: Main booking procedure. Finds an available physical item,
-- creates the reservation, and updates the inventory logistics state.
-- ============================================================
CREATE PROCEDURE pro_reservierung_erstellen(
    IN p_kunde_id INT,
    IN p_geraet_modell_id INT,
    IN p_von_datum DATE,
    IN p_bis_datum DATE,
    IN p_res_nr VARCHAR(20),
    IN p_pos_nr INT,
    -- Delivery address
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

    -- Rollback handling: Atomic Transaction (ACID principles)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validation: start date cannot be in the past
    IF p_von_datum < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Start date cannot be in the past.';
    END IF;

    START TRANSACTION; -- Isolation constraint (ACID principles)
        -- 1. Price determination based on device category
        -- Pessimistic locking implementation (SELECT ... FOR UPDATE)
        SELECT gi.geraet_item_id, gt.preis_pro_tag, gt.lieferpreis 
        INTO v_gewaehltes_item_id, v_tagespreis, v_lieferpreis 
        FROM geraet_item gi
        JOIN geraet_modell gm ON gi.geraet_modell_id = gm.geraet_modell_id
        JOIN geraetetyp gt ON gm.geraetetyp_id = gt.geraetetyp_id
        WHERE gi.geraet_modell_id = p_geraet_modell_id 
          AND gi.item_zustand NOT IN ('defekt', 'wartung')  -- Physical availability check
          AND gi.geraet_item_id NOT IN (                    -- Temporal overlap check
            SELECT rp.geraet_item_id
            FROM reservierungsposition rp
            WHERE rp.von_datum <= p_bis_datum               -- Overlap verification logic
              AND rp.bis_datum >= p_von_datum
          )
        LIMIT 1
        FOR UPDATE; -- Row-level lock (Concurrency Theory)

        -- 2. Safety guard: Abort execution if no stock item is available
        IF v_gewaehltes_item_id IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Kein verfügbares Exemplar für dieses Modell gefunden.';
        END IF;

        -- 3. Procedure call: Search or create delivery address
        CALL pro_adresse_suchen_oder_anlegen(
          p_l_strasse,
          p_l_haus_nr, p_l_zusatz, p_l_plz, p_l_ort, v_l_adr_id);

        -- 4. Insert reservation record
        INSERT INTO reservierung (reservierung_nr, datum, adresse_id, kunde_id)
        VALUES (p_res_nr, NOW(), v_l_adr_id, p_kunde_id);
        
        SET v_res_id = LAST_INSERT_ID();

        -- 5. Insert reservation item line position
        INSERT INTO reservierungsposition (
            reservierungsposition_nr, pos_preis_pro_tag, pos_lieferpreis, 
            von_datum, bis_datum, geraet_item_id, reservierung_id
        )
        VALUES (
            p_pos_nr, v_tagespreis, v_lieferpreis, 
            p_von_datum, p_bis_datum, v_gewaehltes_item_id, v_res_id
        );

        -- 6. Update device state to rented (State pattern modification)
        UPDATE geraet_item 
        SET item_zustand = 'vermietet' 
        WHERE geraet_item_id = v_gewaehltes_item_id;
    COMMIT;
END
//

DELIMITER ;