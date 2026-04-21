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
    CONSTRAINT fk_kunde_adresse -- Referentielle Integrität
        FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id) 
        ON DELETE RESTRICT -- Löschbeschränkung solange Abhängigkeiten existieren
);
CREATE TABLE geraetetyp (
    geraetetyp_id INT AUTO_INCREMENT PRIMARY KEY,
    preis_pro_tag DECIMAL(10, 2) NOT NULL,
    geraetetyp_bezeichnung VARCHAR(100) NOT NULL,
    lieferpreis DECIMAL(10, 2) NOT NULL
);
CREATE TABLE geraet (
    geraet_id INT AUTO_INCREMENT PRIMARY KEY,
    geraete_nr VARCHAR(20) NOT NULL UNIQUE,
    geraet_bezeichnung VARCHAR(100) NOT NULL,
    geraetetyp_id INT NOT NULL,
    CONSTRAINT fk_geraet_typ -- Referentielle Integrität
        FOREIGN KEY (geraetetyp_id) REFERENCES geraetetyp (geraetetyp_id) 
        ON DELETE RESTRICT
);
CREATE TABLE reservierung (
    reservierung_id INT AUTO_INCREMENT PRIMARY KEY,
    reservierung_nr VARCHAR(20) NOT NULL UNIQUE,
    datum DATE NOT NULL,
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
    von_datum DATE NOT NULL,
    bis_datum DATE NOT NULL,
    geraet_id INT NOT NULL,
    reservierung_id INT NOT NULL,
    UNIQUE (reservierung_id, reservierungsposition_nr),
    CONSTRAINT fk_respos_geraet -- Referentielle Integrität
        FOREIGN KEY (geraet_id) REFERENCES geraet (geraet_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_respos_res -- Referentielle Integrität
        FOREIGN KEY (reservierung_id) REFERENCES reservierung (reservierung_id) 
        ON DELETE CASCADE 
);