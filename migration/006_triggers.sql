/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:      006_triggers.sql
-- PROJEKT:     Reservierung DB
-- ZIELSETZUNG: Automatische Validierung und Audit-Protokollierung
-- ============================================================
USE reservierung_db;
/*!40101 SET NAMES utf8mb4 */;

DELIMITER //

-- ============================================================
-- TRIGGER:   trg_validate_dates_insert
-- TABELLE:   reservierungsposition
-- EREIGNIS:  BEFORE INSERT
-- ZWECK:     Verhindert Reservierungen mit einem Startdatum
--            in der Vergangenheit. Schützt auch vor direkten
--            INSERT-Anweisungen außerhalb der Prozedur.
--            Zweite niveau Absicherung.
-- ============================================================
CREATE TRIGGER trg_validate_dates_insert
BEFORE INSERT ON reservierungsposition
FOR EACH ROW
BEGIN
    IF NEW.von_datum < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Startdatum darf nicht in der Vergangenheit liegen.';
    END IF;
END //

-- ============================================================
-- TRIGGER:   trg_prevent_overlap_insert
-- TABELLE:   reservierungsposition
-- EREIGNIS:  BEFORE INSERT
-- ZWECK:     Verhindert Doppelbuchungen eines Geräts durch
--            direkte INSERT-Anweisungen, welche die
--            Geschäftsprozedur umgehen. Die Verfügbarkeit wird
--            über die Funktion fn_ist_item_verfuegbar geprüft.
-- HINWEIS:   MySQL 8.0+ erlaubt mehrere Trigger pro Ereignis.
-- ============================================================
CREATE TRIGGER trg_prevent_overlap_insert
BEFORE INSERT ON reservierungsposition
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

-- ============================================================
-- TRIGGER:   trg_prevent_overlap_update
-- TABELLE:   reservierungsposition
-- EREIGNIS:  BEFORE UPDATE
-- ZWECK:     Verhindert Überschneidungen bei Änderungen
--            einer bestehenden Reservierung.
-- ============================================================
CREATE TRIGGER trg_prevent_overlap_update
BEFORE UPDATE ON reservierungsposition
FOR EACH ROW
BEGIN
    DECLARE v_konflikte INT;

    -- desselben Items - schließt die aktuelle Zeile aus (OLD.id)
    SELECT COUNT(*) INTO v_konflikte
    FROM reservierungsposition rp
    WHERE rp.geraet_item_id = NEW.geraet_item_id
      AND rp.von_datum      <= NEW.bis_datum
      AND rp.bis_datum      >= NEW.von_datum
      AND rp.reservierungsposition_id != OLD.reservierungsposition_id;

    IF v_konflikte > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Zeitraum nicht verfügbar. Überschneidung mit bestehender Reservierung.';
    END IF;
END //

-- ============================================================
-- TRIGGER:   trg_audit_reservierung_insert
-- TABELLE:   reservierung
-- EREIGNIS:  AFTER INSERT
-- ZWECK:     Protokolliert das Erstellen einer Reservierung
--            für die Nachverfolgung und Dokumentation.
-- ============================================================
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

-- ============================================================
-- TRIGGER:   trg_audit_reservierung_update
-- TABELLE:   reservierung
-- EREIGNIS:  AFTER UPDATE
-- ZWECK:     Protokolliert Änderungen einer Reservierung
--            zur Nachverfolgung der Datenänderungen.
-- ============================================================
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

-- ============================================================
-- TRIGGER:   trg_audit_reservierung_delete
-- TABELLE:   reservierung
-- EREIGNIS:  AFTER DELETE
-- ZWECK:     Protokolliert das Löschen einer Reservierung
--            für die vollständige Historie.
-- ============================================================
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

-- ============================================================
-- TRIGGER:   trg_audit_kunde_insert
-- TABELLE:   kunde
-- EREIGNIS:  AFTER INSERT
-- ZWECK:     Protokolliert das Erstellen eines Kunden
--            zur Dokumentation personenbezogener Daten.
-- ============================================================
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

-- ============================================================
-- TRIGGER:   trg_audit_kunde_update
-- TABELLE:   kunde
-- EREIGNIS:  AFTER UPDATE
-- ZWECK:     Protokolliert Änderungen an Kundendaten
--            für Transparenz und DSGVO-Konformität.
-- ============================================================
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

-- ============================================================
-- TRIGGER:   trg_audit_kunde_delete
-- TABELLE:   kunde
-- EREIGNIS:  AFTER DELETE
-- ZWECK:     Protokolliert das Löschen eines Kunden
--            gemäß der Nachweispflicht der Datenverwaltung.
-- ============================================================
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

-- ============================================================
-- TRIGGER:   trg_audit_geraet_item_update
-- TABELLE:   geraet_item
-- EREIGNIS:  AFTER UPDATE
-- ZWECK:     Protokolliert Änderungen des Gerätezustands
--            für die Kontrolle der Verfügbarkeit.
-- ============================================================
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