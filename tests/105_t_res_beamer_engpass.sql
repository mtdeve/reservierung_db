-- ============================================================
-- SKRIPT:    test_reservierung.sql
-- PROJEKT:   Reservierung DB
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- TEST 105: Engpass Beamer — einziges Item bereits gebucht
-- Schritt 1: Buchen → muss funktionieren
-- Schritt 2: Nochmal buchen selber Zeitraum → SIGNAL 45000
-- ============================================================
CALL pro_reservierung_erstellen(
    @kunde_1, @modell_beamer,
    '2029-05-01', '2029-05-05',
    'RES-T006A_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);
SELECT 'TEST 6A BESTANDEN: Beamer erfolgreich gebucht' AS test_ergebnis;

CALL pro_reservierung_erstellen(
    @kunde_2, @modell_beamer,
    '2029-05-03', '2029-05-07',
    'RES-T006B_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);
SELECT 'TEST 6B FEHLGESCHLAGEN: Engpass nicht erkannt' AS test_ergebnis;
