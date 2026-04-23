USE reservierung_db;

-- Esegui questo prima della CALL
SELECT @kunde_id, @modell_macbook;

CALL pro_reservierung_erstellen(
    @kunde_id, @modell_macbook,
    '2026-05-01', '2026-05-05',
    'RES-2026-001', 1,
    'Lieferallee', '55', NULL, '10785', 'Berlin'
);

CALL pro_reservierung_erstellen(
    @kunde_id, @modell_macbook,
    '2026-06-01', '2026-06-05',
    'RES-2026-002', 1,
    'Lieferallee', '55', NULL, '10785', 'Berlin'
);

-- Prima occupa tutti gli item disponibili, poi prova questo
CALL pro_reservierung_erstellen(
    @kunde_id, @modell_macbook,
    '2026-05-03', '2026-05-07',  -- si sovrappone al Test 1
    'RES-2026-003', 1,
    'Lieferallee', '55', NULL, '10785', 'Berlin'
);
-- Con un solo item libero → SIGNAL 45000
-- Con LT-003 ancora libero → prende LT-003

-- LT-002 è già 'defekt' nei seeds, non deve mai essere assegnato
-- verifica:
SELECT geraet_item_id, geraete_nr, item_zustand 
FROM geraet_item;

