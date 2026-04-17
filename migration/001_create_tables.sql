/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

USE reservierung_db;

CREATE TABLE adresse (
    adresse_id INT AUTO_INCREMENT PRIMARY KEY,
    strasse VARCHAR(100) NOT NULL,
    haus_nr VARCHAR(10) NOT NULL,
    adresse_zusatz VARCHAR(100),
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
    FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id)
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
    FOREIGN KEY (geraetetyp_id) REFERENCES geraetetyp (geraetetyp_id)
);

CREATE TABLE reservierung (
    reservierung_id INT AUTO_INCREMENT PRIMARY KEY,
    reservierung_nr VARCHAR(20) NOT NULL UNIQUE,
    datum DATE NOT NULL,
    adresse_id INT NOT NULL,
    kunde_id INT NOT NULL,
    FOREIGN KEY (adresse_id) REFERENCES adresse (adresse_id),
    FOREIGN KEY (kunde_id) REFERENCES kunde (kunde_id)
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
    FOREIGN KEY (geraet_id) REFERENCES geraet (geraet_id),
    FOREIGN KEY (reservierung_id) REFERENCES reservierung (reservierung_id)
);