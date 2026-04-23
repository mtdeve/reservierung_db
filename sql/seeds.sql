USE reservierung_db;

-- Pulizia rapida per rendere lo script ripetibile (Idempotenza)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE reservierungsposition;
TRUNCATE TABLE reservierung;
TRUNCATE TABLE geraet_item;
TRUNCATE TABLE geraet_modell;
TRUNCATE TABLE geraetetyp;
TRUNCATE TABLE kunde;
TRUNCATE TABLE adresse;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Inserimento Tipo e Modello
INSERT INTO geraetetyp (geraetetyp_bezeichnung, preis_pro_tag, lieferpreis) VALUES
('Laptop', 25.00, 10.00),
('Beamer', 18.50, 12.00),
('Tablet', 15.00, 8.00),
('Drucker', 20.00, 15.00);

-- Recuperiamo gli ID per evitare di "indovinare" il numero 1, 2, 3...
SET @type_laptop = (SELECT geraetetyp_id FROM geraetetyp WHERE geraetetyp_bezeichnung = 'Laptop');
SET @type_beamer = (SELECT geraetetyp_id FROM geraetetyp WHERE geraetetyp_bezeichnung = 'Beamer');

INSERT INTO geraet_modell (geraet_bezeichnung, geraetetyp_id) VALUES
('MacBook Pro 14', @type_laptop),
('Epson EB-L', @type_beamer);

SET @modell_macbook = (SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'MacBook Pro 14');

-- 2. Inserimento Item (Esemplari fisici)
INSERT INTO geraet_item (geraete_nr, sn_nr, item_zustand, geraet_modell_id) VALUES
('LT-001', 'SN-MAC-001', 'verfügbar', @modell_macbook),
('LT-002', 'SN-MAC-002', 'defekt', @modell_macbook),
('LT-003', 'SN-MAC-003', 'verfügbar', @modell_macbook);

-- 3. Cliente e Indirizzo
INSERT INTO adresse (strasse, haus_nr, plz, ort) VALUES ('Hauptstraße', '11', '10115', 'Berlin');
SET @adr_id = LAST_INSERT_ID();

INSERT INTO kunde (kunden_nr, nachname, vorname, email, telefon, adresse_id) 
VALUES ('K-2026-002', 'Nicoletti', 'Max', 'max@test.de', '+49123456789', @adr_id);
SET @kunde_id = LAST_INSERT_ID();

-- 4. Test Procedura 3 (Prenotazione)
-- Nota: La procedura internamente chiama la Procedura 2 per l'indirizzo di consegna
CALL pro_reservierung_erstellen(
    @kunde_id, 
    @modell_macbook, 
    '2026-05-01', '2026-05-05', 
    'RES-2026-001', 
    1, 
    'Lieferallee', '55', NULL, '10785', 'Berlin'
);