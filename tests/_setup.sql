-- ============================================================
-- PROJECT:      Reservierung DB
-- PREREQUISITE: seeds.sql must be executed beforehand
-- SETUP:        Retrieve IDs dynamically from seeds (no hardcoded values)
-- ============================================================
USE reservierung_db;

SET @modell_macbook  = (SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'MacBook_Pro_test');
SET @modell_beamer   = (SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'Epson_EB_test');
SET @modell_drucker  = (SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'HP_Laser_test');
SET @modell_ipad     = (SELECT geraet_modell_id FROM geraet_modell WHERE geraet_bezeichnung = 'iPad_Pro_test');

SET @kunde_1         = (SELECT kunde_id FROM kunde WHERE kunden_nr = 'K-001_test');
SET @kunde_2         = (SELECT kunde_id FROM kunde WHERE kunden_nr = 'K-002_test');