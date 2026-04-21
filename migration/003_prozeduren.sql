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
        INSERT INTO adresse (strasse, haus_nr, adresse_zusatz, plz, ort)
        VALUES (p_strasse, p_haus_nr, p_zusatz, p_plz, p_ort);
        
        SET p_adr_id = LAST_INSERT_ID();
    END IF;
END //


-- PROZEDUR:    pro_kunde_mit_adresse_anlegen
CREATE PROCEDURE pro_kunde_mit_adresse_anlegen(
    -- Dati Cliente
    IN p_kunden_nr VARCHAR(20),
    IN p_nname VARCHAR(100),
    IN p_vname VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefon VARCHAR(20),
    -- Dati Indirizzo
    IN p_strasse VARCHAR(100),
    IN p_haus_nr VARCHAR(10),
    IN p_zusatz VARCHAR(20),
    IN p_plz VARCHAR(10),
    IN p_ort VARCHAR(100)
)
BEGIN
    DECLARE v_adr_id INT; -- Variabile locale per contenere l'ID indirizzo

    -- Gestione errori atomica
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        -- 1. Chiamiamo la procedura 1 per gestire l'indirizzo
        CALL pro_adresse_suchen_oder_anlegen(p_strasse, p_haus_nr, p_zusatz, p_plz, p_ort, v_adr_id);

        -- 2. Usiamo l'ID ottenuto (v_adr_id) per creare il cliente
        INSERT INTO kunde (vorname, nachname, email, kunden_nr, adresse_id)
        VALUES (p_vname, p_nname, p_email, p_kunden_nr, v_adr_id);
    COMMIT;
END //

-- PROZEDUR:    pro_reservierung_erstellen
CREATE PROCEDURE pro_reservierung_erstellen(
    IN p_kunde_id INT,
    IN p_geraet_id INT,
    IN p_von DATE,
    IN p_bis DATE,
    IN p_res_nr VARCHAR(20),
    IN p_pos_nr INT,
    -- Dati indirizzo di consegna (Lieferadresse)
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
    DECLARE v_verfuegbar INT;

    -- Handler per la sicurezza dei dati
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- 1. Recupero prezzi e info dispositivo dal tipo di dispositivo
    SELECT gt.preis_pro_tag, gt.lieferpreis 
    INTO v_tagespreis, v_lieferpreis
    FROM geraet g
    JOIN geraetetyp gt ON g.geraetetyp_id = gt.geraetetyp_id
    WHERE g.geraet_id = p_geraet_id;

    START TRANSACTION;
        -- 2. Gestione indirizzo di consegna tramite la nostra utility
        CALL pro_adresse_suchen_oder_anlegen(p_l_strasse, p_l_haus_nr, p_l_zusatz, p_l_plz, p_l_ort, v_l_adr_id);

        -- 3. Inserimento Testata Prenotazione
        INSERT INTO reservierung (reservierung_nr, datum, adresse_id, kunde_id)
        VALUES (p_res_nr, CURDATE(), v_l_adr_id, p_kunde_id);
        
        SET v_res_id = LAST_INSERT_ID();

        -- 4. Inserimento Posizione Prenotazione
        INSERT INTO reservierungsposition (
            reservierungsposition_nr, pos_preis_pro_tag, pos_lieferpreis, 
            von_datum, bis_datum, geraet_id, reservierung_id
        )
        VALUES (
            p_pos_nr, v_tagespreis, v_lieferpreis, 
            p_von, p_bis, p_geraet_id, v_res_id
        );
    COMMIT;
END //
DELIMITER ;