CREATE TABLE reservierungsposition (
   reservierungsposition_id INT AUTO_INCREMENT PRIMARY KEY,
   pos_nr INT NOT NULL,
   preis_pro_tag DECIMAL(10,2) NOT NULL,
   lieferpreis DECIMAL(10,2) NOT NULL,
   von_datum DATE NOT NULL,
   bis_datum DATE NOT NULL,
   geraet_id INT NOT NULL,
   reservierung_id INT NOT NULL,
   UNIQUE (reservierung_id, pos_nr),
   FOREIGN KEY (geraet_id) REFERENCES geraet(geraet_id),
   FOREIGN KEY (reservierung_id) REFERENCES reservierung(reservierung_id)
);

