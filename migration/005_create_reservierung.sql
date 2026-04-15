CREATE TABLE reservierung (
   reservierung_id INT AUTO_INCREMENT PRIMARY KEY,
   reservierungsnr VARCHAR(20) NOT NULL UNIQUE,
   datum DATE NOT NULL,
   adresse_id INT NOT NULL,
   kunde_id INT NOT NULL,
   FOREIGN KEY (adresse_id) REFERENCES adresse(adresse_id),
   FOREIGN KEY (kunde_id) REFERENCES kunde(kunde_id)
);