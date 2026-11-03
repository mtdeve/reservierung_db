/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

USE reservierung_db;

-- Schutzmaßnahme für "SIGNED"-Werte:
ALTER TABLE geraetetyp
ADD CONSTRAINT chk_geraetetyp_preis CHECK (preis_pro_tag >= 0);

ALTER TABLE position
ADD CONSTRAINT chk_pos_preis CHECK (pos_preis_pro_tag >= 0);

ALTER TABLE position
ADD CONSTRAINT chk_pos_nr CHECK (position_nr > 0);

-- 2. Datumsangaben (zeitliche Konsistenz)
ALTER TABLE position
ADD CONSTRAINT chk_datum_range CHECK (bis_datum >= von_datum);

-- 3. Kunde (E-Mail, Telefon)
ALTER TABLE kunde
ADD CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%');

ALTER TABLE kunde
ADD CONSTRAINT chk_telefon_length CHECK (CHAR_LENGTH(telefon) >= 6);

-- Verhindert Doubletten (schmutzige Daten) im System.
-- Schutz vor Bot-Registrierungen und Systemüberlastung durch Fake-Konten.
ALTER TABLE kunde ADD CONSTRAINT uq_email UNIQUE (email);

-- 4. Adresse (Postleitzahl)
-- Beispiel: Deutsche PLZ 5 Zifern aber auch internationale Formate möglich
-- (z.B. mit REGEXP '^[A-Z0-9 -]{2,10}$' für England = SW1A 1AA Niederlande = 1234 AB oder USA = 90210-1234)
ALTER TABLE adresse
ADD CONSTRAINT chk_plz_format CHECK (plz REGEXP '^[0-9]{5}$');

-- 5. Performance-Optimierung (Indizes)
CREATE INDEX idx_pos_zeitraum ON position (von_datum, bis_datum);

CREATE INDEX idx_kunde_nachname ON kunde (nachname);