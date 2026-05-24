# Data Dictionary — Reservierung DB

## 1. Overview

| | |
|---|---|
| **Project** | Reservierung DB |
| **Version** | 1.0 |
| **Author** | mtdeve |
| **License** | GNU Affero General Public License v3.0 |
| **Database** | MySQL 8.0.44 |
| **Charset** | utf8mb4 |
| **Collation** | utf8mb4_unicode_ci |
| **Timezone** | UTC (SET time_zone = '+00:00') |

### Description
Rental management database for physical devices.
Handles customers, device inventory, and reservations
with temporal availability logic.

### Migration Files

| File | Purpose |
|---|---|
| `000_create_database.sql` | Database creation and base configuration |
| `001_create_tables.sql` | Table structure and foreign keys |
| `002_add_constraints.sql` | Data integrity checks and indexes |
| `003_prozeduren.sql` | Stored procedures for business logic |
| `004_functions.sql` | Reusable functions for calculations |
---

## 2. Tables

### `adresse`
Stores reusable addresses for both customers and delivery locations.
The same address is shared across entities and never duplicated.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `adresse_id` | INT | PK, AUTO_INCREMENT | Internal unique identifier |
| `strasse` | VARCHAR(100) | NOT NULL | Street name |
| `haus_nr` | VARCHAR(10) | NOT NULL | House number — VARCHAR supports formats like '12a' |
| `adresse_zusatz` | VARCHAR(20) | NULL | Optional addition e.g. apartment number |
| `plz` | VARCHAR(10) | NOT NULL | Postal code — German format, 5 digits |
| `ort` | VARCHAR(100) | NOT NULL | City |

| | |
|---|---|
| **Referenced by** | `kunde.adresse_id`, `reservierung.adresse_id` |
| **Managed by** | `pro_adresse_suchen_oder_anlegen` |

---

### `kunde`
Customer registry. Each customer is linked to exactly one address.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `kunde_id` | INT | PK, AUTO_INCREMENT | Internal unique identifier |
| `kunden_nr` | VARCHAR(20) | NOT NULL, UNIQUE | Business identifier e.g. 'K-001' |
| `nachname` | VARCHAR(100) | NOT NULL | Last name |
| `vorname` | VARCHAR(100) | NOT NULL | First name |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE | Email address |
| `telefon` | VARCHAR(20) | NOT NULL | Phone number — VARCHAR supports international formats |
| `adresse_id` | INT | FK → adresse, RESTRICT | Customer address |

| | |
|---|---|
| **References** | `adresse.adresse_id` |
| **Referenced by** | `reservierung.kunde_id` |
| **Managed by** | `pro_kunde_mit_adresse_anlegen` |

---

### `geraetetyp`
Device category. Defines the pricing for all models belonging to this category.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `geraetetyp_id` | INT | PK, AUTO_INCREMENT | Internal unique identifier |
| `geraetetyp_bezeichnung` | VARCHAR(100) | NOT NULL | Category name e.g. 'Laptop', 'Beamer' |
| `preis_pro_tag` | DECIMAL(10,2) | NOT NULL | Daily rental price |
| `lieferpreis` | DECIMAL(10,2) | NOT NULL | One-time delivery price |

| | |
|---|---|
| **Referenced by** | `geraet_modell.geraetetyp_id` |

---

### `geraet_modell`
Specific device model belonging to a category.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `geraet_modell_id` | INT | PK, AUTO_INCREMENT | Internal unique identifier |
| `geraet_bezeichnung` | VARCHAR(100) | NOT NULL | Model name e.g. 'MacBook Pro 14' |
| `geraetetyp_id` | INT | FK → geraetetyp, RESTRICT | Parent category |

| | |
|---|---|
| **References** | `geraetetyp.geraetetyp_id` |
| **Referenced by** | `geraet_item.geraet_modell_id` |

---

### `geraet_item`
Physical device instance with serial number and current status.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `geraet_item_id` | INT | PK, AUTO_INCREMENT | Internal unique identifier |
| `geraete_nr` | VARCHAR(20) | NOT NULL, UNIQUE | Inventory number e.g. 'LT-001' |
| `sn_nr` | VARCHAR(100) | NOT NULL, UNIQUE | Serial number — unique per physical device |
| `item_zustand` | VARCHAR(20) | NOT NULL, DEFAULT 'verfügbar' | Current physical status |
| `anschaffungsdatum` | DATE | NULL | Purchase date |
| `geraet_modell_id` | INT | FK → geraet_modell, RESTRICT | Parent model |

**`item_zustand` allowed values:**

| Value | Meaning |
|---|---|
| `verfügbar` | Physically available in warehouse |
| `vermietet` | Currently out on rental |
| `defekt` | Broken — excluded from availability checks |
| `wartung` | Under maintenance — excluded from availability checks |

| | |
|---|---|
| **References** | `geraet_modell.geraet_modell_id` |
| **Referenced by** | `reservierungsposition.geraet_item_id` |
| **Managed by** | `pro_reservierung_erstellen`, `fn_ist_item_verfuegbar` |

---

### `reservierung`
Reservation header linked to a customer and a delivery address.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `reservierung_id` | INT | PK, AUTO_INCREMENT | Internal unique identifier |
| `reservierung_nr` | VARCHAR(20) | NOT NULL, UNIQUE | Business identifier e.g. 'RES-2026-001' |
| `datum` | TIMESTAMP | NOT NULL | Creation timestamp — stored in UTC |
| `adresse_id` | INT | FK → adresse, RESTRICT | Delivery address |
| `kunde_id` | INT | FK → kunde, RESTRICT | Customer |

| | |
|---|---|
| **References** | `adresse.adresse_id`, `kunde.kunde_id` |
| **Referenced by** | `reservierungsposition.reservierung_id` |
| **Managed by** | `pro_reservierung_erstellen` |

---

### `reservierungsposition`
Reservation line item — links a specific device instance to a reservation with rental period and price snapshot.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `reservierungsposition_id` | INT | PK, AUTO_INCREMENT | Internal unique identifier |
| `reservierungsposition_nr` | INT | NOT NULL | Line number within reservation e.g. 1, 2, 3 |
| `pos_preis_pro_tag` | DECIMAL(10,2) | NOT NULL | Daily price snapshot at booking time |
| `pos_lieferpreis` | DECIMAL(10,2) | NOT NULL | Delivery price snapshot at booking time |
| `von_datum` | DATE | NOT NULL | Rental start date |
| `bis_datum` | DATE | NOT NULL | Rental end date |
| `geraet_item_id` | INT | FK → geraet_item, RESTRICT | Reserved device instance |
| `reservierung_id` | INT | FK → reservierung, CASCADE | Parent reservation |

| | |
|---|---|
| **References** | `geraet_item.geraet_item_id`, `reservierung.reservierung_id` |
| **Managed by** | `pro_reservierung_erstellen` |
| **Used by** | `fn_ist_item_verfuegbar`, `fn_calc_pos_gesamt` |
---

## 3. Constraints

### CHECK Constraints

| Table | Constraint Name | Rule | Description |
|---|---|---|---|
| `geraetetyp` | `chk_geraetetyp_preis` | `preis_pro_tag >= 0` | Daily price cannot be negative |
| `geraetetyp` | `chk_geraetetyp_lieferpreis` | `lieferpreis >= 0` | Delivery price cannot be negative |
| `geraet_item` | `chk_item_zustand` | `IN ('verfügbar', 'defekt', 'wartung', 'vermietet')` | Only allowed status values |
| `reservierungsposition` | `chk_pos_preis` | `pos_preis_pro_tag >= 0` | Snapshot price cannot be negative |
| `reservierungsposition` | `chk_pos_lieferpreis` | `pos_lieferpreis >= 0` | Snapshot delivery price cannot be negative |
| `reservierungsposition` | `chk_datum_range` | `bis_datum >= von_datum` | End date must be after or equal to start date |
| `reservierungsposition` | `chk_pos_nr` | `reservierungsposition_nr > 0` | Line number must be positive |
| `kunde` | `chk_email_format` | `email LIKE '%@%.%'` | Minimum email format validation |
| `kunde` | `chk_telefon_length` | `CHAR_LENGTH(telefon) >= 6` | Minimum phone number length |
| `adresse` | `chk_plz_format` | `plz REGEXP '^[0-9]{5}$'` | German postal code — exactly 5 digits |

---

### UNIQUE Constraints

| Table | Constraint Name | Column(s) | Description |
|---|---|---|---|
| `kunde` | `uq_email` | `email` | One account per email address |
| `kunde` | — | `kunden_nr` | Business identifier must be unique |
| `geraet_item` | — | `geraete_nr` | Inventory number must be unique |
| `geraet_item` | — | `sn_nr` | Serial number must be unique |
| `reservierung` | — | `reservierung_nr` | Business identifier must be unique |
| `reservierungsposition` | — | `(reservierung_id, reservierungsposition_nr)` | No duplicate line numbers within same reservation |

---

### Foreign Key Constraints

| Constraint Name | Table | Column | References | On Delete |
|---|---|---|---|---|
| `fk_kunde_adresse` | `kunde` | `adresse_id` | `adresse.adresse_id` | RESTRICT |
| `fk_modell_typ` | `geraet_modell` | `geraetetyp_id` | `geraetetyp.geraetetyp_id` | RESTRICT |
| `fk_item_modell` | `geraet_item` | `geraet_modell_id` | `geraet_modell.geraet_modell_id` | RESTRICT |
| `fk_res_adresse` | `reservierung` | `adresse_id` | `adresse.adresse_id` | RESTRICT |
| `fk_res_kunde` | `reservierung` | `kunde_id` | `kunde.kunde_id` | RESTRICT |
| `fk_respos_item` | `reservierungsposition` | `geraet_item_id` | `geraet_item.geraet_item_id` | RESTRICT |
| `fk_respos_res` | `reservierungsposition` | `reservierung_id` | `reservierung.reservierung_id` | CASCADE |
---

## 4. Stored Procedures

### `pro_adresse_suchen_oder_anlegen`
Searches for an existing address matching all fields. If not found, creates a new one.
Prevents address duplication across the database.

**Parameters:**

| Name | Direction | Type | Description |
|---|---|---|---|
| `p_strasse` | IN | VARCHAR(100) | Street name |
| `p_haus_nr` | IN | VARCHAR(10) | House number |
| `p_zusatz` | IN | VARCHAR(20) | Optional address addition — nullable |
| `p_plz` | IN | VARCHAR(10) | Postal code |
| `p_ort` | IN | VARCHAR(100) | City |
| `p_adr_id` | OUT | INT | ID of found or newly created address |

**Behavior:**
- Uses `<=>` NULL-safe operator for `adresse_zusatz` comparison
- If address exists → returns existing `adresse_id`
- If address does not exist → inserts and returns new `adresse_id`
- Called internally by `pro_kunde_mit_adresse_anlegen` and `pro_reservierung_erstellen`

**Error handling:** none — delegates to caller transaction

---

### `pro_kunde_mit_adresse_anlegen`
Creates a new customer and resolves the address in a single atomic transaction.

**Parameters:**

| Name | Direction | Type | Description |
|---|---|---|---|
| `p_kunden_nr` | IN | VARCHAR(20) | Business identifier e.g. 'K-001' |
| `p_nname` | IN | VARCHAR(100) | Last name |
| `p_vname` | IN | VARCHAR(100) | First name |
| `p_email` | IN | VARCHAR(100) | Email address |
| `p_telefon` | IN | VARCHAR(20) | Phone number |
| `p_strasse` | IN | VARCHAR(100) | Street name |
| `p_haus_nr` | IN | VARCHAR(10) | House number |
| `p_zusatz` | IN | VARCHAR(20) | Optional address addition |
| `p_plz` | IN | VARCHAR(10) | Postal code |
| `p_ort` | IN | VARCHAR(100) | City |

**Behavior:**
- Opens a transaction
- Calls `pro_adresse_suchen_oder_anlegen` to resolve address ID
- Inserts customer with resolved address ID
- Commits on success

**Error handling:** `DECLARE EXIT HANDLER FOR SQLEXCEPTION` → ROLLBACK + RESIGNAL

---

### `pro_reservierung_erstellen`
Core business procedure. Creates a complete reservation for one device model.
Finds an available item, locks it, creates the reservation and position, and updates the device status.

**Parameters:**

| Name | Direction | Type | Description |
|---|---|---|---|
| `p_kunde_id` | IN | INT | Customer internal ID |
| `p_geraet_modell_id` | IN | INT | Requested device model ID |
| `p_von_datum` | IN | DATE | Rental start date |
| `p_bis_datum` | IN | DATE | Rental end date |
| `p_res_nr` | IN | VARCHAR(20) | Reservation business identifier |
| `p_pos_nr` | IN | INT | Line number within reservation |
| `p_l_strasse` | IN | VARCHAR(100) | Delivery street name |
| `p_l_haus_nr` | IN | VARCHAR(10) | Delivery house number |
| `p_l_zusatz` | IN | VARCHAR(20) | Delivery address addition — nullable |
| `p_l_plz` | IN | VARCHAR(10) | Delivery postal code |
| `p_l_ort` | IN | VARCHAR(100) | Delivery city |

**Execution flow:**
1. Resolve or create delivery address
2. SELECT available item with FOR UPDATE (pessimistic lock) — excludes defekt/wartung and overlapping reservations
3. If no item found → SIGNAL 45000
4. INSERT reservierung
5. INSERT reservierungsposition with price snapshot
6. UPDATE geraet_item SET item_zustand = 'vermietet'

**Error handling:** `DECLARE EXIT HANDLER FOR SQLEXCEPTION` → ROLLBACK + RESIGNAL

**Raises:**

| SQLSTATE | Message | Condition |
|---|---|---|
| `45000` | Kein verfügbares Exemplar für dieses Modell gefunden. | No available item found for requested model and period |

## 5. Functions

### `fn_calc_tage`
Calculates the number of rental days between two dates.

| | |
|---|---|
| **Returns** | INT |
| **Deterministic** | YES |

**Parameters:**

| Name | Type | Description |
|---|---|---|
| `p_von` | DATE | Rental start date |
| `p_bis` | DATE | Rental end date |

**Behavior:**
- Returns `DATEDIFF(p_bis, p_von)`
- The return day is not counted as a rental day — consistent with hotel check-in/check-out logic
- Raises SIGNAL 45000 if `p_bis < p_von`

**Example:**
`fn_calc_tage('2026-05-01', '2026-05-05')` → `4`

**Raises:**

| SQLSTATE | Message | Condition |
|---|---|---|
| `45000` | Enddatum darf nicht vor dem Startdatum liegen. | End date is before start date |

**Used by:** `fn_calc_pos_gesamt`

---

### `fn_calc_pos_gesamt`
Calculates the total price of a reservation position.
Formula: `(rental days × daily price) + delivery price`

| | |
|---|---|
| **Returns** | DECIMAL(10,2) |
| **Deterministic** | YES |

**Parameters:**

| Name | Type | Description |
|---|---|---|
| `p_von` | DATE | Rental start date |
| `p_bis` | DATE | Rental end date |
| `p_preis_pro_tag` | DECIMAL(10,2) | Daily rental price |
| `p_lieferpreis` | DECIMAL(10,2) | One-time delivery price |

**Behavior:**
- Calls `fn_calc_tage` internally — does not duplicate day calculation logic
- Delivery price is added once regardless of rental duration

**Example:**
`fn_calc_pos_gesamt('2026-05-01', '2026-05-05', 25.00, 10.00)` → `110.00`

**Used by:** views for revenue reporting

---

### `fn_ist_item_verfuegbar`
Checks whether a specific device instance is available for a given period.
Combines physical status check and temporal overlap check.

| | |
|---|---|
| **Returns** | TINYINT (1 = available, 0 = not available) |
| **Deterministic** | NO — depends on current database content |

**Parameters:**

| Name | Type | Description |
|---|---|---|
| `p_item_id` | INT | Device instance ID to check |
| `p_von` | DATE | Requested start date |
| `p_bis` | DATE | Requested end date |

**Behavior:**
- Returns `0` if `item_zustand IN ('defekt', 'wartung')`
- Returns `0` if an overlapping reservation exists in `reservierungsposition`
- Returns `1` only if both checks pass
- Uses LEFT JOIN — ensures items with no reservations are still checked for physical status
- Overlap condition: `rp.von_datum <= p_bis AND rp.bis_datum >= p_von`

**Example:**
`fn_ist_item_verfuegbar(1, '2026-07-01', '2026-07-05')` → `1` or `0`

**Used by:** views for availability calendar, triggers for booking validation
