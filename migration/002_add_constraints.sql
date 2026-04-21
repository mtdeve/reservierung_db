/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:    002_add_constraints.sql
-- PROJEKT:   Reservierung DB (SQL_pr_01)
-- ZIELSETZUNG: Datenintegrität (CHECK) und Performance (INDEX)
-- ============================================================
USE reservierung_db;
-- 1. Preis-Tabellen (keine negativen Werte)
ALTER TABLE geraetetyp
ADD CONSTRAINT chk_geraetetyp_preis
CHECK (preis_pro_tag >= 0);

ALTER TABLE geraetetyp
ADD CONSTRAINT chk_geraetetyp_lieferpreis
CHECK (lieferpreis >= 0);

ALTER TABLE reservierungsposition
ADD CONSTRAINT chk_pos_preis
CHECK (pos_preis_pro_tag >= 0);

ALTER TABLE reservierungsposition
ADD CONSTRAINT chk_pos_lieferpreis
CHECK (pos_lieferpreis >= 0);

-- 2. Datumsangaben (zeitliche Konsistenz)
ALTER TABLE reservierungsposition
ADD CONSTRAINT chk_datum_range
CHECK (bis_datum >= von_datum);

-- 3. Kunde (E-Mail, Telefon)
ALTER TABLE kunde
ADD CONSTRAINT chk_email_format
CHECK (email LIKE '%@%.%');

ALTER TABLE kunde
ADD CONSTRAINT chk_telefon_length
CHECK (CHAR_LENGTH(telefon) >= 6);

-- optional, aber empfohlen
/*
 * DATENINTEGRITÄT: Verhindert Doubletten (schmutzige Daten) im System.
 * PERFORMANCE: Automatischer Index beschleunigt Login- und Suchanfragen erheblich.
 * DSGVO-COMPLIANCE (Art. 5 & 25): Gewährleistet Datenrichtigkeit und erleichtert 
 * Lösch- sowie Auskunftsanfragen (Privacy by Design).
 * SICHERHEIT: Schutz vor Bot-Registrierungen und Systemüberlastung durch Fake-Konten.
 */
ALTER TABLE kunde
ADD CONSTRAINT uq_email UNIQUE (email);

-- 4. Adresse (Postleitzahl)
-- Beispiel: Deutsche PLZ 5 Zifern aber auch internationale Formate möglich 
-- (z.B. mit REGEXP '^[A-Z0-9 -]{2,10}$' für England = SW1A 1AA Niederlande = 1234 AB oder USA = 90210-1234)
ALTER TABLE adresse
ADD CONSTRAINT chk_plz_format
CHECK (plz REGEXP '^[0-9]{5}$');

-- 5. Position (Nummerierung)
ALTER TABLE reservierungsposition
ADD CONSTRAINT chk_pos_nr
CHECK (reservierungsposition_nr > 0);

-- 7. ID-INTEGRITÄT (SICHERSTELLUNG POSITIVER IDS)
/*
* SIGNED-Typen für die Java-Kompatibilität (zB Spring Boot),
* aber CHECK-Constraints, um negative IDs zu verhindern.
*/

ALTER TABLE adresse 
    ADD CONSTRAINT chk_adresse_id_pos 
    CHECK (adresse_id > 0);

ALTER TABLE kunde 
    ADD CONSTRAINT chk_kunde_id_pos 
    CHECK (kunde_id > 0);

ALTER TABLE geraetetyp 
    ADD CONSTRAINT chk_geraetetyp_id_pos 
    CHECK (geraetetyp_id > 0);

ALTER TABLE geraet 
    ADD CONSTRAINT chk_geraet_id_pos 
    CHECK (geraet_id > 0);

ALTER TABLE reservierung 
    ADD CONSTRAINT chk_res_id_pos 
    CHECK (reservierung_id > 0);

ALTER TABLE reservierungsposition 
    ADD CONSTRAINT chk_respos_id_pos 
    CHECK (reservierungsposition_id > 0);

-- 7. Performance-Optimierung (Indizes)
CREATE INDEX idx_pos_zeitraum
ON reservierungsposition(von_datum, bis_datum);
CREATE INDEX idx_kunde_nachname 
ON kunde(nachname);