CREATE TABLE kunde (
   kunde_id INT AUTO_INCREMENT PRIMARY KEY,
   kundennr VARCHAR(20) NOT NULL UNIQUE,
   name VARCHAR(100) NOT NULL,
   vorname VARCHAR(100) NOT NULL,
   adresse_id INT NOT NULL,
   FOREIGN KEY (adresse_id) REFERENCES adresse(adresse_id)
);