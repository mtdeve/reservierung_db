/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

USE reservierung_db;

DELIMITER //
CREATE PROCEDURE pro_adresse_suchen_oder_anlegen(
    IN p_strasse VARCHAR(100),
    IN p_haus_nr VARCHAR(10),
    IN p_zusatz VARCHAR(20), 
    IN p_plz VARCHAR(10),
    IN p_ort VARCHAR(100),
    OUT p_adresse_id INT
)
BEGIN
    SET p_adresse_id = NULL;
    SELECT adresse_id INTO p_adresse_id 
    FROM adresse 
    WHERE strasse = p_strasse 
      AND haus_nr = p_haus_nr 
      AND adresse_zusatz <=> p_zusatz   -- In "adresse_zusatz" NULL-Werte erlaubt (<=>)
      AND plz = p_plz 
      AND ort = p_ort
    LIMIT 1;
    
    IF p_adresse_id IS NULL THEN        -- Wenn keine,Adresse einlegen
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
        
        SET p_adresse_id = LAST_INSERT_ID();
    END IF;
END //
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
    DECLARE v_adresse_id INT;

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
          p_strasse, p_haus_nr, p_zusatz, p_plz, p_ort, v_adresse_id
        );

        -- 2. Kundenbeleg unter Verwendung der abgerufenen Adress-ID erstellen
        INSERT INTO kunde (kunden_nr, nachname, vorname, email, telefon, adresse_id)
        VALUES (p_kunden_nr, p_nname, p_vname, p_email, p_telefon, v_adresse_id);
    COMMIT;
END //

CREATE PROCEDURE pro_reservierung_erstellen(
    IN p_kunde_id INT
)
BEGIN
    DECLARE v_reservierung_nr VARCHAR(20);
    DECLARE v_token VARCHAR(10);
    DECLARE v_token_hash CHAR(64);
    DECLARE v_reservierung_zustand_id INT;
    DECLARE v_adresse_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        SET v_reservierung_nr = CONCAT('R-', DATE_FORMAT(NOW(), '%y%m%d%H%i%s'), '-', LEFT(HEX(RANDOM_BYTES(3)), 5));
        SET v_token = HEX(RANDOM_BYTES(5));     -- HEX() liefert größbuchstaben
        SET v_token_hash = SHA2(v_token, 256);  -- SHA2() liefert hex in kleinschreibung für konsistenz
        -- Adress-ID des Kunden ermitteln
        SELECT adresse_id INTO v_adresse_id
        FROM kunde
        WHERE kunde_id = p_kunde_id;
        -- hardcoded, Vermeidung von stiller Abfrage-Crush 
        SELECT reservierung_zustand_id INTO v_reservierung_zustand_id
        FROM reservierung_zustand
        WHERE reservierung_zustand_bezeichnung = 'offen';
        -- Daten hinzufügen
        INSERT INTO reservierung (
            reservierung_nr,
            reservierung_hash,
            datum,
            reservierung_zustand,
            adresse_id,
            kunde_id
        )
        VALUES (
            v_reservierung_nr,
            v_token_hash,
            NOW(),
            v_reservierung_zustand_id,
            v_adresse_id,
            p_kunde_id
        );

        IF IS_ROLE_IN_SESSION('admin_role') THEN
          SELECT v_token AS token, v_reservierung_nr AS reservierungsnummer;
        END IF;

    COMMIT;
END //

DELIMITER ;


CREATE PROCEDURE pro_position_erstellen(
    IN p_reservierung_id INT,
    IN p_geraet_model_id INT,
    IN p_von_datum DATE,
    IN p_bis_datum DATE,
    OUT p_position_nr INT
)
BEGIN
    DECLARE v_gewaehltes_item_id INT;
    DECLARE v_tagespreis DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validierung: Startdatum darf nicht in der Vergangenheit liegen - erste niveau.
    IF p_von_datum < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Das startdatum darf nicht in der Vergangenheit liegen.';
    END IF;

    START TRANSACTION;
        SET p_position_nr = 1;
        SET v_reservierung_id = LAST_INSERT_ID();
        SET v_position_nr = 1;

        -- 1. Preisermittlung basierend auf der GeräteType
        SELECT gi.geraet_item_id, gt.preis_pro_tag                    -- pessimistischem Sperren (SELECT ... FOR UPDATE)
        INTO v_gewaehltes_item_id, v_tagespreis
        FROM geraet_item gi
        JOIN geraet_modell gm ON gi.geraet_modell_id = gm.geraet_modell_id
        JOIN geraetetyp gt ON gm.geraetetyp_id = gt.geraetetyp_id
        WHERE gi.geraet_modell_id = p_geraet_modell_id
          AND gi.item_zustand NOT IN ('defekt', 'wartung')             -- Physische Verfügbarkeitsprüfung
          AND gi.geraet_item_id NOT IN (                               -- Zeitliche Überschneidungsprüfung
            SELECT rp.geraet_item_id
            FROM position rp
            WHERE rp.von_datum <= p_bis_datum
              AND rp.bis_datum >= p_von_datum
          )
        LIMIT 1                                                        -- Sperre auf Zeilenebene / Row-Level-Lock (Nebenläufigkeitstheorie)
        FOR UPDATE;

        -- Eine erste Schutzstufe, um Doppelbuchungen zu vermeiden
        IF NOT v_gefunden_item THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Kein verfügbares Exemplar für dieses Modell gefunden.';
        END IF;
    INSERT INTO position (
        position_nr,
        pos_preis_pro_tag,
        von_datum, bis_datum,
        geraet_item_id,
        reservierung_id
    )
    VALUES (
        p_position_nr,
        v_tagespreis,
        p_von_datum, p_bis_datum,
        v_gewaehltes_item_id,
        p_reservierung_id
    );
END //

CREATE PROCEDURE pro_token_notfall(
    IN p_reservierung_id INT
)
BEGIN
    DECLARE v_token VARCHAR(10);
    DECLARE v_token_hash CHAR(64);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK; 
        -- Fehler weiterreichen über die Datenbankschnittstelle an den aufrufenden Client
        -- (sei es die CLI, eine GUI wie MySQL Workbench oder eine Backend-Applikation)
        RESIGNAL;
    END;

    START TRANSACTION;
        -- 1. Token generieren
        SET v_token = HEX(RANDOMBYTES(5));
        SET v_token_hash = SHA2(v_token, 256);

        -- 2. Reservierung aktualisieren
        UPDATE reservierung
        SET reservierung_hash = v_token_hash
        WHERE reservierung_id = p_reservierung_id;
    COMMIT;

    SELECT v_token AS neuer_token;
END //