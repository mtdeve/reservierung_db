-- ============================================================
-- PROJEKT:   Reservierung DB
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- TEST 102: Overlap — beide verfügbaren Items belegt
-- Vorbereitung: LT-001 und LT-002 im selben Zeitraum buchen
-- Erwartet: SIGNAL 45000
-- ============================================================

-- Erst LT-002 für denselben Zeitraum wie TEST 1 belegen
CALL pro_reservierung_erstellen(
    @kunde_2, @modell_macbook,
    '2026-05-01', '2026-05-05',
    'RES-T003A_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);

-- Jetzt sind beide verfügbaren Items belegt → muss scheitern
CALL pro_reservierung_erstellen(
    @kunde_1, @modell_macbook,
    '2026-05-03', '2026-05-07',
    'RES-T003B_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);
SELECT 'TEST 3 FEHLGESCHLAGEN: Overlap wurde nicht erkannt' AS test_ergebnis;

