-- ============================================================
-- SKRIPT:    seeds.sql
-- PROJEKT:   Reservierung DB
-- ZWECK:     Reproduzierbare Testdaten für alle Szenarien
-- HINWEIS:   Alle Namen tragen das Suffix _test
--            Keine Session-Variablen — nur pure INSERT-Statements
-- ============================================================
USE reservierung_db;
/*!40101 SET NAMES utf8mb4 */;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE reservierungsposition;
TRUNCATE TABLE reservierung;
TRUNCATE TABLE geraet_item;
TRUNCATE TABLE geraet_modell;
TRUNCATE TABLE geraetetyp;
TRUNCATE TABLE kunde;
TRUNCATE TABLE adresse;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. GERÄTETYPEN
-- ============================================================
INSERT INTO geraetetyp (geraetetyp_bezeichnung, preis_pro_tag, lieferpreis) VALUES
('Laptop_test',  25.00, 10.00),   -- hat mehrere Items → Mehrfach-Item-Tests
('Beamer_test',  18.50, 12.00),   -- hat nur ein Item  → Engpass-Test
('Tablet_test',  15.00,  8.00),   -- hat gar kein Item → Modell-ohne-Item-Test
('Drucker_test', 20.00, 15.00);   -- reserviert        → Overlap-Test

-- 2. GERÄTEMODELLE
-- ============================================================
INSERT INTO geraet_modell (geraet_bezeichnung, geraetetyp_id) VALUES
-- Laptop: 2 verfügbar + 1 defekt + 1 wartung → deckt alle Zustand-Tests ab
('MacBook_Pro_test',    (SELECT geraetetyp_id FROM geraetetyp WHERE geraetetyp_bezeichnung = 'Laptop_test')),
-- Beamer: nur 1 verfügbar → Engpass bei gleichzeitiger Buchung
('Epson_EB_test',       (SELECT geraetetyp_id FROM geraetetyp WHERE geraetetyp_bezeichnung = 'Beamer_test')),
-- Drucker: Item bereits vorgebucht → Overlap-Test
('HP_Laser_test',       (SELECT geraetetyp_id FROM geraetetyp WHERE geraetetyp_bezeichnung = 'Drucker_test')),
-- Tablet: kein Item vorhanden → SIGNAL 45000 sofort
('iPad_Pro_test',       (SELECT geraetetyp_id FROM geraetetyp WHERE geraetetyp_bezeichnung = 'Tablet_test'));

-- ============================================================
-- 3. GERÄTE ITEMS
-- ============================================================
INSERT INTO geraet_item (geraete_nr, sn_nr, item_zustand, anschaffungsdatum, geraet_modell_id) VALUES
-- MacBook: alle 4 Zustände abgedeckt
('LT-001_test', 'SN-MAC-001_test', 'verfügbar', '2024-01-10',
(SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'MacBook_Pro_test')),
('LT-002_test', 'SN-MAC-002_test', 'verfügbar', '2024-01-10',
(SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'MacBook_Pro_test')),
('LT-003_test', 'SN-MAC-003_test', 'defekt',    '2024-01-10',
(SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'MacBook_Pro_test')),
('LT-004_test', 'SN-MAC-004_test', 'wartung',   '2024-01-10',
(SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'MacBook_Pro_test')),
-- Beamer: nur 1 → Engpass
('BM-001_test', 'SN-EPS-001_test', 'verfügbar', '2023-06-15',
(SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'Epson_EB_test')),
-- Drucker: wird direkt vorgebucht für Overlap-Test
('DR-001_test', 'SN-HP-001_test',  'verfügbar', '2023-09-01',
(SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'HP_Laser_test'));
-- iPad: absichtlich kein Item → SIGNAL 45000

-- ============================================================
-- 4. ADRESSEN
-- ============================================================
INSERT INTO adresse (strasse, haus_nr, adresse_zusatz, plz, ort) VALUES
('Hauptstrasse_test', '11',  NULL,   '10115', 'Berlin'),   -- geteilt von Kunde 1 + 2 → Adress-Wiederverwendung
('Testallee_test',    '99',  'EG',   '20095', 'Hamburg'),  -- nur Kunde 3
('Lieferweg_test',    '55',  NULL,   '10785', 'Berlin');    -- Lieferadresse für Tests

-- ============================================================
-- 5. KUNDEN
-- Kunde 1 + 2 teilen dieselbe Adresse → Test pro_adresse_suchen_oder_anlegen
-- ============================================================
INSERT INTO kunde (kunden_nr, nachname, vorname, email, telefon, adresse_id) VALUES
('K-001_test', 'Muster_test',   'Max_test',  'max_test@test.de',   '0301234567',
(SELECT adresse_id FROM adresse WHERE strasse = 'Hauptstrasse_test')),
('K-002_test', 'Beispiel_test', 'Eva_test',  'eva_test@test.de',   '0309876543',
(SELECT adresse_id FROM adresse WHERE strasse = 'Hauptstrasse_test')),
('K-003_test', 'Sample_test',   'Hans_test', 'hans_test@test.de',  '0401122334',
(SELECT adresse_id FROM adresse WHERE strasse = 'Testallee_test'));

-- ============================================================
-- 6. VORHANDENE RESERVIERUNG (für Overlap-Test)
-- Drucker DR-001_test ist vom 01.05 bis 05.05 bereits gebucht
-- ============================================================
INSERT INTO reservierung (reservierung_nr, datum, adresse_id, kunde_id) VALUES
('RES-SEED-001_test', NOW(),
    (SELECT adresse_id FROM adresse WHERE strasse = 'Lieferweg_test'),
    (SELECT kunde_id   FROM kunde    WHERE kunden_nr = 'K-001_test')
);

INSERT INTO reservierungsposition (
    reservierungsposition_nr, pos_preis_pro_tag, pos_lieferpreis,
    von_datum, bis_datum, geraet_item_id, reservierung_id
) VALUES (
    1, 20.00, 15.00,
    '2026-05-01', '2026-05-05',
    (SELECT geraet_item_id FROM geraet_item WHERE geraete_nr = 'DR-001_test'),
    (SELECT reservierung_id FROM reservierung WHERE reservierung_nr = 'RES-SEED-001_test')
);