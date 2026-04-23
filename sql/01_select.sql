USE reservierung_db;

SELECT * FROM reservierung WHERE reservierung_nr = 'RES-2026-001';

SELECT r.reservierung_id, a.strasse, a.haus_nr, a.ort 
FROM reservierung r 
JOIN adresse a ON r.adresse_id = a.adresse_id
WHERE r.reservierung_nr = 'RES-2026-001';

SELECT rp.reservierungsposition_id, m.geraet_bezeichnung, i.geraete_nr
FROM reservierungsposition rp
JOIN geraet_item i ON rp.geraet_item_id = i.geraet_item_id
JOIN geraet_modell m ON i.geraet_modell_id = m.geraet_modell_id
WHERE rp.reservierung_id = (SELECT reservierung_id FROM reservierung WHERE reservierung_nr = 'RES-2026-001');

SELECT geraete_nr, item_zustand FROM geraet_item WHERE geraete_nr = 'LT-001';