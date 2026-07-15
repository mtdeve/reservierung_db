/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:      007_access.sql
-- PROJEKT:     Reservierung DB
-- ZIELSETZUNG: Zugriffssteuerung
-- ============================================================
CREATE ROLE IF NOT EXISTS admin_role, mitarbeiter_role, kunde_role;

-- Admin: Vollzugriff auf alle Datenbanken
GRANT ALL PRIVILEGES ON reservierung_db.* TO 'admin_role';
GRANT ALL PRIVILEGES ON reservierung_audit_db.* TO 'admin_role';

-- Mitarbeiter: Zugriff auf Reservierungsdatenbank
GRANT SELECT, INSERT, UPDATE, DELETE ON reservierung_db.* TO 'mitarbeiter_role';

-- Kunde: Nur lesender Zugriff auf Reservierungsdatenbank
GRANT SELECT ON reservierung_db.* TO 'kunde_role';