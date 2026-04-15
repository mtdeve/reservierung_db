CREATE TABLE geraet (
   geraet_id INT AUTO_INCREMENT PRIMARY KEY,
   geraetenr VARCHAR(20) NOT NULL UNIQUE,
   bezeichnung VARCHAR(100) NOT NULL,
   geraetetyp_id INT NOT NULL,
   FOREIGN KEY (geraetetyp_id) REFERENCES geraetetyp(geraetetyp_id)
);