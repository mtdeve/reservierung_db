-- ============================================================
-- PROJECT:      Reservierung DB
-- PURPOSE:      Validation of booking logic and procedures
-- PREREQUISITE: seeds.sql must be executed beforehand
-- FINAL REPORT: 109
-- ============================================================
-- Retrieve valid IDs dynamically from seeds
SET @kunde_id = (SELECT kunde_id FROM kunde LIMIT 1);
SET @modell_id = (SELECT geraet_modell_id FROM geraet_modell LIMIT 1);

-- Attempt to create a reservation with a start date in the past (yesterday)
CALL pro_reservierung_erstellen(
    @kunde_id,
    @modell_id,
    DATE_SUB(CURDATE(), INTERVAL 1 DAY), -- von_datum: Yesterday
    DATE_ADD(CURDATE(), INTERVAL 5 DAY), -- bis_datum: Future date
    'RES-TEST-109',
    1,
    'Teststrasse', '10', NULL, '12345', 'Testort'
);