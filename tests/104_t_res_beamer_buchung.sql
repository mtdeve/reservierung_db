-- ============================================================
-- SKRIPT:    test_reservierung.sql
-- PROJEKT:   Reservierung DB
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- TEST 104: Kein Item vorhanden (iPad hat keine Items)
-- Erwartet: SIGNAL 45000
-- ============================================================
CALL pro_reservierung_erstellen(
    @kunde_1, @modell_ipad,
    '2026-05-01', '2026-05-05',
    'RES-T005_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);
SELECT 'TEST 5 FEHLGESCHLAGEN: Kein SIGNAL bei fehlendem Item' AS test_ergebnis;
