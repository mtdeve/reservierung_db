-- ============================================================
-- SKRIPT:    test_reservierung.sql
-- PROJEKT:   Reservierung DB
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- TEST 107: Adress-Wiederverwendung
-- Lieferadresse bereits in der DB → darf nicht dupliziert werden
-- ============================================================
CALL pro_reservierung_erstellen(
    @kunde_1, @modell_macbook,
    '2026-08-01', '2026-08-05',
    'RES-T008_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'  -- selbe Adresse wie Seeds
);

SELECT 
    COUNT(*) AS anzahl_adressen,
    CASE 
        WHEN COUNT(*) = 1 THEN 'TEST 8 BESTANDEN: Adresse wurde wiederverwendet'
        ELSE                   'TEST 8 FEHLGESCHLAGEN: Adresse wurde dupliziert'
    END AS test_ergebnis
FROM adresse 
WHERE strasse = 'Lieferweg_test' 
  AND haus_nr = '55' 
  AND plz = '10785';