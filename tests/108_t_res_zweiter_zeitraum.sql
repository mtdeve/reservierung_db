-- ============================================================
-- PROJEKT:   Reservierung DB
-- ZWECK:     Validierung der Buchungslogik und Prozeduren
-- VORAUSSETZUNG: seeds.sql wurde bereits ausgeführt
-- ABSCHLUSSBERICHT: 108

-- ============================================================
SELECT 
    r.reservierung_nr,
    k.kunden_nr,
    rp.von_datum,
    rp.bis_datum,
    gi.geraete_nr,
    gi.item_zustand,
    gm.geraet_bezeichnung
FROM reservierung r
JOIN kunde k                  ON r.kunde_id          = k.kunde_id
JOIN reservierungsposition rp ON r.reservierung_id   = rp.reservierung_id
JOIN geraet_item gi           ON rp.geraet_item_id   = gi.geraet_item_id
JOIN geraet_modell gm         ON gi.geraet_modell_id = gm.geraet_modell_id
ORDER BY rp.von_datum, r.reservierung_nr;