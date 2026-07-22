/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:      001_create_tables.sql
-- PROJEKT:     Reservierung DB
-- ZIELSETZUNG: Definition der Tabellenstrukturen und Relationen
-- ============================================================
-- ============================================================
-- AUDIT-DATENBANK
-- Separate Datenbank für DSGVO-konforme Protokollierung
-- Wird NICHT gelöscht beim Zurücksetzen der Hauptdatenbank
-- ============================================================
USE reservierung_audit_db;
/*!40101 SET NAMES utf8mb4 */; 

CREATE TABLE IF NOT EXISTS audit_log (
    audit_id     INT AUTO_INCREMENT PRIMARY KEY,
    tabelle      VARCHAR(50)  NOT NULL,             -- betroffene Tabelle
    operation    VARCHAR(10)  NOT NULL,             -- INSERT, UPDATE oder DELETE
    datensatz_id INT          NOT NULL,             -- ID des betroffenen Datensatzes
    wert_vorher  TEXT,                              -- Wert vor der Änderung
    wert_nachher TEXT,                              -- Wert nach der Änderung
    benutzer     VARCHAR(100),                      -- angemeldeter Datenbankbenutzer
    zeitstempel  TIMESTAMP    DEFAULT NOW()         -- Zeitpunkt der Änderung (UTC)
) ENGINE=InnoDB;

-- ============================================================
-- HAUPTDATENBANK
-- HINWEIS: "SIGNED" (als default) auf alle Werte stellen. Es vermeidet Kompatibilitätsprobleme 
-- mit den Datenbanksystemen und frameworks. Es bleiben 2^31 Ziffern übrig.
-- ============================================================
USE reservierung_db;

CREATE TABLE adresse (
    adresse_id INT AUTO_INCREMENT PRIMARY KEY,
    strasse VARCHAR(100) NOT NULL,
    haus_nr VARCHAR(10) NOT NULL,
    adresse_zusatz VARCHAR(20),
    plz VARCHAR(10) NOT NULL,
    ort VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE kunde (
    kunde_id INT AUTO_INCREMENT PRIMARY KEY,
    kunden_nr VARCHAR(20) NOT NULL UNIQUE,
    nachname VARCHAR(100) NOT NULL,
    vorname VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefon VARCHAR(20) NOT NULL,
    adresse_id INT NOT NULL,
    -- Referentielle Integrität - die automatische Benennung "ibfk_1" wird vermeidet durch die explizite Benennung der FK-Constraint.
    -- ON DELETE RESTRICT - Löschbeschränkung solange Abhängigkeiten existieren 
    CONSTRAINT fk_kunde_adresse
        FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id) 
        ON DELETE RESTRICT 
) ENGINE=InnoDB;

CREATE TABLE geraetetyp (
    geraetetyp_id INT AUTO_INCREMENT PRIMARY KEY,
    preis_pro_tag DECIMAL(10, 2) NOT NULL,
    geraetetyp_bezeichnung VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE geraet_modell (
    geraet_modell_id INT AUTO_INCREMENT PRIMARY KEY,
    geraet_bezeichnung VARCHAR(100) NOT NULL,
    geraetetyp_id INT NOT NULL,
    -- Referentielle Integrität auch hier also als standartmäßige Praxis
    CONSTRAINT fk_modell_typ
        FOREIGN KEY (geraetetyp_id) REFERENCES geraetetyp (geraetetyp_id) 
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE geraet_item (
    geraet_item_id INT AUTO_INCREMENT PRIMARY KEY,
    geraete_nr VARCHAR(20) NOT NULL UNIQUE,
    sn_nr VARCHAR(100) NOT NULL UNIQUE,
    item_zustand VARCHAR(20) NOT NULL DEFAULT 'verfügbar',
    anschaffungsdatum DATE,
    geraet_modell_id INT NOT NULL,
    CONSTRAINT fk_item_modell
        FOREIGN KEY (geraet_modell_id) REFERENCES geraet_modell (geraet_modell_id) 
        ON DELETE RESTRICT,
    CONSTRAINT chk_item_zustand CHECK (item_zustand IN ('verfügbar', 'defekt', 'wartung', 'vermietet'))
) ENGINE=InnoDB;

CREATE TABLE reservierung (
    reservierung_id INT AUTO_INCREMENT PRIMARY KEY,
    reservierung_nr VARCHAR(20) NOT NULL UNIQUE,
    reservierung_hash VARCHAR(64) NOT NULL UNIQUE,
    -- Arbeitet mit UTC-Zeit, wie an anfangs besprochen (SET time_zone = '+00:00';)
    datum TIMESTAMP NOT NULL,
    adresse_id INT NOT NULL,
    kunde_id INT NOT NULL,
    CONSTRAINT fk_res_adresse
        FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_res_kunde
        FOREIGN KEY (kunde_id) REFERENCES kunde (kunde_id) 
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE position (
    position_id INT AUTO_INCREMENT PRIMARY KEY,
    position_nr INT NOT NULL UNIQUE,
    pos_preis_pro_tag DECIMAL(10, 2) NOT NULL,
    -- Absoluter Datentyp für die Tagespreise
    -- SIGNED (als default) Kompatibilitätsprobleme mit den Datenbanksystemen vermeidet; es bleiben 2^31 Ziffern übrig.
    von_datum DATE NOT NULL,
    bis_datum DATE NOT NULL,
    geraet_item_id INT NOT NULL,
    reservierung_id INT NOT NULL,
    -- Zusammengesetzter Unique-Key
    UNIQUE (reservierung_id, position_nr),
    CONSTRAINT fk_respos_item
        FOREIGN KEY (geraet_item_id) REFERENCES geraet_item (geraet_item_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_respos_res
        FOREIGN KEY (reservierung_id) REFERENCES reservierung (reservierung_id) 
        ON DELETE CASCADE 
) ENGINE=InnoDB;
