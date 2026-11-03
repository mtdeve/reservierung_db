/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

USE reservierung_db;

DELIMITER //

CREATE TRIGGER trg_validate_dates_insert
BEFORE INSERT ON position
FOR EACH ROW
BEGIN
    IF NEW.von_datum < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Startdatum darf nicht in der Vergangenheit liegen.';
    END IF;
END //

CREATE TRIGGER trg_prevent_overlap_insert
BEFORE INSERT ON position
FOR EACH ROW
BEGIN
    IF fn_ist_item_verfuegbar(
        NEW.geraet_item_id,
        NEW.von_datum,
        NEW.bis_datum
    ) = FALSE THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Das Gerät ist im gewünschten Zeitraum nicht verfügbar.';
    END IF;
END //


CREATE TRIGGER trg_prevent_overlap_update
BEFORE UPDATE ON position
FOR EACH ROW
BEGIN
    DECLARE v_konflikte INT;

    -- desselben Items - schließt die aktuelle Zeile aus (OLD.id)
    SELECT COUNT(*) INTO v_konflikte
    FROM position rp
    WHERE rp.geraet_item_id = NEW.geraet_item_id
      AND rp.von_datum      <= NEW.bis_datum
      AND rp.bis_datum      >= NEW.von_datum
      AND rp.position_id != OLD.position_id;

    IF v_konflikte > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Zeitraum nicht verfügbar. Überschneidung mit bestehender Reservierung.';
    END IF;
END //


CREATE TRIGGER trg_audit_reservierung_insert
AFTER INSERT ON reservierung
FOR EACH ROW
BEGIN
    INSERT INTO reservierung_audit_db.audit_log
    (
        tabelle,
        operation,
        datensatz_id,
        wert_vorher,
        wert_nachher,
        benutzer
    )
    VALUES
    (
        'reservierung',
        'INSERT',
        NEW.reservierung_id,
        NULL,
        CONCAT(
            'reservierung_nr=', NEW.reservierung_nr,
            ', datum=', NEW.datum,
            ', adresse_id=', NEW.adresse_id,
            ', kunde_id=', NEW.kunde_id
        ),
        USER()
    );

END //

CREATE TRIGGER trg_audit_reservierung_update
AFTER UPDATE ON reservierung
FOR EACH ROW
BEGIN
    INSERT INTO reservierung_audit_db.audit_log
    (
        tabelle,
        operation,
        datensatz_id,
        wert_vorher,
        wert_nachher,
        benutzer
    )
    VALUES
    (
        'reservierung',
        'UPDATE',
        NEW.reservierung_id,
        CONCAT(
            'reservierung_nr=', OLD.reservierung_nr,
            ', datum=', OLD.datum,
            ', adresse_id=', OLD.adresse_id,
            ', kunde_id=', OLD.kunde_id
        ),
        CONCAT(
            'reservierung_nr=', NEW.reservierung_nr,
            ', datum=', NEW.datum,
            ', adresse_id=', NEW.adresse_id,
            ', kunde_id=', NEW.kunde_id
        ),
        USER()
    );

END //


CREATE TRIGGER trg_audit_reservierung_delete
AFTER DELETE ON reservierung
FOR EACH ROW
BEGIN
    INSERT INTO reservierung_audit_db.audit_log
    (
        tabelle,
        operation,
        datensatz_id,
        wert_vorher,
        wert_nachher,
        benutzer
    )
    VALUES
    (
        'reservierung',
        'DELETE',
        OLD.reservierung_id,
        CONCAT(
            'reservierung_nr=', OLD.reservierung_nr,
            ', datum=', OLD.datum,
            ', adresse_id=', OLD.adresse_id,
            ', kunde_id=', OLD.kunde_id
        ),
        NULL,
        USER()
    );

END //


CREATE TRIGGER trg_audit_kunde_insert
AFTER INSERT ON kunde
FOR EACH ROW
BEGIN
    INSERT INTO reservierung_audit_db.audit_log
    (
        tabelle,
        operation,
        datensatz_id,
        wert_vorher,
        wert_nachher,
        benutzer
    )
    VALUES
    (
        'kunde',
        'INSERT',
        NEW.kunde_id,
        NULL,
        CONCAT(
            'kunden_nr=', NEW.kunden_nr,
            ', nachname=', NEW.nachname,
            ', vorname=', NEW.vorname,
            ', email=', NEW.email,
            ', telefon=', NEW.telefon,
            ', adresse_id=', NEW.adresse_id
        ),
        USER()
    );

END //


CREATE TRIGGER trg_audit_kunde_update
AFTER UPDATE ON kunde
FOR EACH ROW
BEGIN
    INSERT INTO reservierung_audit_db.audit_log
    (
        tabelle,
        operation,
        datensatz_id,
        wert_vorher,
        wert_nachher,
        benutzer
    )
    VALUES
    (
        'kunde',
        'UPDATE',
        NEW.kunde_id,
        CONCAT(
            'kunden_nr=', OLD.kunden_nr,
            ', nachname=', OLD.nachname,
            ', vorname=', OLD.vorname,
            ', email=', OLD.email,
            ', telefon=', OLD.telefon,
            ', adresse_id=', OLD.adresse_id
        ),
        CONCAT(
            'kunden_nr=', NEW.kunden_nr,
            ', nachname=', NEW.nachname,
            ', vorname=', NEW.vorname,
            ', email=', NEW.email,
            ', telefon=', NEW.telefon,
            ', adresse_id=', NEW.adresse_id
        ),
        USER()
    );
END //


CREATE TRIGGER trg_audit_kunde_delete
AFTER DELETE ON kunde
FOR EACH ROW
BEGIN
    INSERT INTO reservierung_audit_db.audit_log
    (
        tabelle,
        operation,
        datensatz_id,
        wert_vorher,
        wert_nachher,
        benutzer
    )
    VALUES
    (
        'kunde',
        'DELETE',
        OLD.kunde_id,
        CONCAT(
            'kunden_nr=', OLD.kunden_nr,
            ', nachname=', OLD.nachname,
            ', vorname=', OLD.vorname,
            ', email=', OLD.email,
            ', telefon=', OLD.telefon,
            ', adresse_id=', OLD.adresse_id
        ),
        NULL,
        USER()
    );
END //


CREATE TRIGGER trg_audit_geraet_item_update
AFTER UPDATE ON geraet_item
FOR EACH ROW
BEGIN
    IF OLD.item_zustand <> NEW.item_zustand THEN
        INSERT INTO reservierung_audit_db.audit_log
        (
            tabelle,
            operation,
            datensatz_id,
            wert_vorher,
            wert_nachher,
            benutzer
        )
        VALUES
        (
            'geraet_item',
            'UPDATE',
            NEW.geraet_item_id,
            CONCAT('item_zustand=', OLD.item_zustand),
            CONCAT('item_zustand=', NEW.item_zustand),
            USER()
        );
    END IF;
END //

DELIMITER ;