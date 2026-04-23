/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:    001_create_tables.sql
-- PROJEKT:   Reservierung DB
-- ZIELSETZUNG: Definition der Tabellenstrukturen und Relationen
-- ============================================================
USE reservierung_db;
CREATE TABLE adresse (
    adresse_id INT AUTO_INCREMENT PRIMARY KEY,
    strasse VARCHAR(100) NOT NULL,
    haus_nr VARCHAR(10) NOT NULL,
    adresse_zusatz VARCHAR(20),
    plz VARCHAR(10) NOT NULL,
    ort VARCHAR(100) NOT NULL
);
CREATE TABLE kunde (
    kunde_id INT AUTO_INCREMENT PRIMARY KEY,
    kunden_nr VARCHAR(20) NOT NULL UNIQUE,
    nachname VARCHAR(100) NOT NULL,
    vorname VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefon VARCHAR(20) NOT NULL,
    adresse_id INT NOT NULL,
    CONSTRAINT fk_kunde_adresse -- Referentielle Integrität (ibfk_1 vermeidet)
        FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id) 
        ON DELETE RESTRICT -- Löschbeschränkung solange Abhängigkeiten existieren
);
CREATE TABLE geraetetyp (
    geraetetyp_id INT AUTO_INCREMENT PRIMARY KEY,
    preis_pro_tag DECIMAL(10, 2) NOT NULL,
    geraetetyp_bezeichnung VARCHAR(100) NOT NULL,
    lieferpreis DECIMAL(10, 2) NOT NULL
);
CREATE TABLE geraet_modell (
    geraet_modell_id INT AUTO_INCREMENT PRIMARY KEY,
    geraet_bezeichnung VARCHAR(100) NOT NULL,
    geraetetyp_id INT NOT NULL,
    CONSTRAINT fk_modell_typ -- Referentielle Integrität
        FOREIGN KEY (geraetetyp_id) REFERENCES geraetetyp (geraetetyp_id) 
        ON DELETE RESTRICT
);
CREATE TABLE geraet_item (
    geraet_item_id INT AUTO_INCREMENT PRIMARY KEY,
    geraete_nr VARCHAR(20) NOT NULL UNIQUE,
    sn_nr VARCHAR(100) NOT NULL UNIQUE,
    item_zustand VARCHAR(20) NOT NULL DEFAULT 'verfügbar',
    anschaffungsdatum DATE,
    geraet_modell_id INT NOT NULL,
    CONSTRAINT fk_item_modell -- Referentielle Integrität
        FOREIGN KEY (geraet_modell_id) REFERENCES geraet_modell (geraet_modell_id) 
        ON DELETE RESTRICT,
    CONSTRAINT chk_item_zustand CHECK (item_zustand IN ('verfügbar', 'defekt', 'wartung', 'vermietet'))
);
CREATE TABLE reservierung (
    reservierung_id INT AUTO_INCREMENT PRIMARY KEY,
    reservierung_nr VARCHAR(20) NOT NULL UNIQUE,
    datum TIMESTAMP NOT NULL, -- Arbeitet mit UTC-Zeit, wie an anfangs besprochen (SET time_zone = '+00:00';)
    adresse_id INT NOT NULL,
    kunde_id INT NOT NULL,
    CONSTRAINT fk_res_adresse -- Referentielle Integrität
        FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_res_kunde -- Referentielle Integrität
        FOREIGN KEY (kunde_id) REFERENCES kunde (kunde_id) 
        ON DELETE RESTRICT
);
CREATE TABLE reservierungsposition (
    reservierungsposition_id INT AUTO_INCREMENT PRIMARY KEY,
    reservierungsposition_nr INT NOT NULL,
    pos_preis_pro_tag DECIMAL(10, 2) NOT NULL,
    pos_lieferpreis DECIMAL(10, 2) NOT NULL,
    von_datum DATE NOT NULL, -- Absoluter Datentyp für die Tagespreise
    bis_datum DATE NOT NULL,
    geraet_item_id INT NOT NULL,
    reservierung_id INT NOT NULL,
    UNIQUE (reservierung_id, reservierungsposition_nr), -- Zusammengesetzter Unique-Key
    CONSTRAINT fk_respos_item -- Referentielle Integrität
        FOREIGN KEY (geraet_item_id) REFERENCES geraet_item (geraet_item_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_respos_res -- Referentielle Integrität
        FOREIGN KEY (reservierung_id) REFERENCES reservierung (reservierung_id) 
        ON DELETE CASCADE 
);