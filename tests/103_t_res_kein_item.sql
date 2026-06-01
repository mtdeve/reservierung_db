-- ============================================================
-- SKRIPT:    test_reservierung.sql
-- PROJEKT:   Reservierung DB
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- TEST 103: Kein Item vorhanden (iPad hat keine Items)
-- Erwartet: SIGNAL 45000
-- ============================================================
CALL pro_reservierung_erstellen(
    @kunde_1, @modell_macbook,
    '2029-07-01', '2029-07-05',
    'RES-T004_test', 1,
    'Lieferweg_test', '55', NULL, '10785', 'Berlin'
);

SELECT 
    CASE 
        WHEN gi.item_zustand IN ('defekt', 'wartung') 
        THEN 'TEST 4 FEHLGESCHLAGEN: Defektes Item wurde gebucht'
        ELSE 'TEST 4 BESTANDEN: Nur verfügbare Items gebucht'
    END AS test_ergebnis,
    gi.geraete_nr,
    gi.item_zustand
FROM reservierung r
JOIN reservierungsposition rp ON r.reservierung_id = rp.reservierung_id
JOIN geraet_item gi           ON rp.geraet_item_id  = gi.geraet_item_id
WHERE r.reservierung_nr = 'RES-T004_test';
