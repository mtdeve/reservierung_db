-- ============================================================
-- PROJEKT:   Reservierung DB
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- TEST 100: Normale Buchung
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- Erwartet: ERFOLG — LT-001_test oder LT-002_test wird gebucht
-- ============================================================
CALL pro_reservierung_erstellen(
    @kunde_1, @modell_macbook,
    '2029-05-01', '2029-05-05',
    'RES-T001_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);

