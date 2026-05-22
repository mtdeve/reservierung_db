-- ============================================================
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- TEST 101: Zweite Buchung anderer Zeitraum — selbes Modell
-- Erwartet: ERFOLG — zweites verfügbares Item wird gebucht

-- ============================================================
CALL pro_reservierung_erstellen(
    @kunde_2, @modell_macbook,
    '2026-06-01', '2026-06-05',
    'RES-T002_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);


