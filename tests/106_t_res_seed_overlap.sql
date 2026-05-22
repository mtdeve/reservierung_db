-- ============================================================
-- SKRIPT:    test_reservierung.sql
-- PROJEKT:   Reservierung DB
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- TEST 106: Overlap Drucker — bereits im Seed vorgebucht
-- Seed hat DR-001_test von 01.05 bis 05.05 gebucht
-- Erwartet: SIGNAL 45000
-- ============================================================
CALL pro_reservierung_erstellen(
    @kunde_1, @modell_drucker,
    '2026-05-03', '2026-05-07',
    'RES-T007_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);
SELECT 'TEST 7 FEHLGESCHLAGEN: Seed-Overlap nicht erkannt' AS test_ergebnis;