CREATE TABLE geraetetyp (
   geraetetyp_id INT AUTO_INCREMENT PRIMARY KEY,
   preis_pro_tag DECIMAL(10,2) NOT NULL,
   bezeichnung VARCHAR(100) NOT NULL,
   lieferpreis DECIMAL(10,2) NOT NULL
);