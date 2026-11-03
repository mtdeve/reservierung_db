/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- Änderungsprotokoll, getrennt von den Anwendungsdaten
USE reservierung_audit_db;

CREATE TABLE audit_log (
    audit_id     INT AUTO_INCREMENT PRIMARY KEY,
    tabelle      VARCHAR(64)  NOT NULL,
    operation    VARCHAR(10)  NOT NULL,
    datensatz_id INT          NOT NULL,
    wert_vorher  TEXT,
    wert_nachher TEXT,
    benutzer     VARCHAR(64),
    zeitstempel  TIMESTAMP    DEFAULT NOW()
);


-- "SIGNED" (als default) auf alle Werte stellen. Es vermeidet Kompatibilitätsprobleme 
-- mit den Datenbanksystemen und frameworks. Es bleiben 2^31 Ziffern übrig.
USE reservierung_db;

CREATE TABLE adresse (
    adresse_id INT AUTO_INCREMENT PRIMARY KEY,
    strasse VARCHAR(64) NOT NULL,
    haus_nr VARCHAR(10) NOT NULL,
    adresse_zusatz VARCHAR(20),
    plz VARCHAR(10) NOT NULL,
    ort VARCHAR(64) NOT NULL
);

CREATE TABLE kunde (
    kunde_id INT AUTO_INCREMENT PRIMARY KEY,
    kunden_nr VARCHAR(20) NOT NULL UNIQUE,
    nachname VARCHAR(64) NOT NULL,
    vorname VARCHAR(64) NOT NULL,
    email VARCHAR(254) NOT NULL,
    telefon VARCHAR(20) NOT NULL,
    adresse_id INT NOT NULL,
    -- Referentielle Integrität - die automatische Benennung "ibfk_1" wird vermeidet durch die explizite Benennung der FK-Constraint.
    -- ON DELETE RESTRICT - Löschbeschränkung solange Abhängigkeiten existieren 
    CONSTRAINT fk_kunde_adresse
        FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id) 
        ON DELETE RESTRICT 
);

CREATE TABLE geraetetyp (
    geraetetyp_id INT AUTO_INCREMENT PRIMARY KEY,
    preis_pro_tag DECIMAL(10, 2) NOT NULL,
    geraetetyp_bezeichnung VARCHAR(64) NOT NULL
);

CREATE TABLE geraet_modell (
    geraet_modell_id INT AUTO_INCREMENT PRIMARY KEY,
    geraet_bezeichnung VARCHAR(64) NOT NULL,
    geraetetyp_id INT NOT NULL,
    -- Referentielle Integrität auch hier also als standartmäßige Praxis
    CONSTRAINT fk_modell_typ
        FOREIGN KEY (geraetetyp_id) REFERENCES geraetetyp (geraetetyp_id) 
        ON DELETE RESTRICT
);

CREATE TABLE item_zustand (
    item_zustand_id INT AUTO_INCREMENT PRIMARY KEY,
    item_zustand_bezeichnung VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE geraet_item (
    geraet_item_id INT AUTO_INCREMENT PRIMARY KEY,
    geraete_nr VARCHAR(20) NOT NULL UNIQUE,
    serien_nr VARCHAR(64) NOT NULL UNIQUE,
    anschaffungsdatum DATE,
    item_zustand_id INT NOT NULL,
    geraet_modell_id INT NOT NULL,
    CONSTRAINT fk_geraet_zustand
        FOREIGN KEY (item_zustand_id) REFERENCES item_zustand (item_zustand_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_item_modell
        FOREIGN KEY (geraet_modell_id) REFERENCES geraet_modell (geraet_modell_id) 
        ON DELETE RESTRICT
);

CREATE TABLE reservierung_zustand (
    reservierung_zustand_id INT AUTO_INCREMENT PRIMARY KEY,
    reservierung_zustand_bezeichnung VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE reservierung (
    reservierung_id INT AUTO_INCREMENT PRIMARY KEY,
    reservierung_nr VARCHAR(20) NOT NULL UNIQUE,
    reservierung_hash VARCHAR(64) NOT NULL UNIQUE,
    -- Arbeitet mit UTC-Zeit, wie an anfangs besprochen (SET time_zone = '+00:00';)
    datum TIMESTAMP NOT NULL,
    reservierung_zustand_id INT NOT NULL,
    kunde_id INT NOT NULL,
    adresse_id INT NOT NULL,
    CONSTRAINT fk_res_zustand
        FOREIGN KEY (reservierung_zustand_id) REFERENCES reservierung_zustand (reservierung_zustand_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_res_kunde
        FOREIGN KEY (kunde_id) REFERENCES kunde (kunde_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_res_adresse
        FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id) 
        ON DELETE RESTRICT
);

CREATE TABLE position (
    position_id INT AUTO_INCREMENT PRIMARY KEY,
    position_nr INT NOT NULL,
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
);