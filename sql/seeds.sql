INSERT INTO adresse (strasse, hausnr, plz, ort) VALUES
('Bahnhofstrasse', '12', '65549', 'Limburg'),
('Hauptstrasse', '7a', '56410', 'Montabaur'),
('Gartenweg', '3', '56068', 'Koblenz'),
('Schulstrasse', '22', '65582', 'Diez');
 
 
INSERT INTO kunde (kundennr, name, vorname, adresse_id) VALUES
('K-1001', 'Schmidt', 'Alice', 1),
('K-1002', 'Meyer', 'Jonas', 2),
('K-1003', 'Becker', 'Laura', 3),
('K-1004', 'Wagner', 'Tim', 4);
 
 
INSERT INTO geraetetyp (bezeichnung, preis_pro_tag, lieferpreis) VALUES
('Laptop', 25.00, 10.00),
('Beamer', 18.50, 12.00),
('Tablet', 15.00, 8.00),
('Drucker', 20.00, 15.00);
 
 
INSERT INTO geraet (geraetenr, bezeichnung, geraetetyp_id) VALUES
('G-2001', 'Dell Latitude 5540', 1),
('G-2002', 'Lenovo ThinkPad E15', 1),
('G-2003', 'Epson EB-X49', 2),
('G-2004', 'Acer X1328WH', 2),
('G-2005', 'Samsung Galaxy Tab S8', 3),
('G-2006', 'Apple iPad 10', 3),
('G-2007', 'HP LaserJet Pro', 4),
('G-2008', 'Brother MFC-L2710DW', 4);
 
 
INSERT INTO reservierung (reservierungsnr, datum, kunde_id, adresse_id) VALUES
('R-3001', '2026-04-01', 1, 1),
('R-3002', '2026-04-15', 2, 2),
('R-3003', '2026-05-01', 3, 3),
('R-3004', '2026-05-20', 4, 4);
 
 
INSERT INTO reservierungsposition
(geraet_id, reservierung_id, pos_nr, preis_pro_tag, lieferpreis, von_datum, bis_datum)
VALUES
(1, 1, 1, 25.00, 10.00, '2026-04-20', '2026-04-25'),
(3, 1, 2, 18.50, 12.00, '2026-04-20', '2026-04-22'),
(5, 2, 1, 15.00, 8.00, '2026-05-01', '2026-05-03'),
(7, 3, 1, 20.00, 15.00, '2026-05-10', '2026-05-15'),
(2, 4, 1, 25.00, 10.00, '2026-06-01', '2026-06-07'),
(4, 4, 2, 18.50, 12.00, '2026-06-01', '2026-06-04');