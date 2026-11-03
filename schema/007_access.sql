/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

CREATE ROLE IF NOT EXISTS admin_role, app_role;

-- Admin: Vollzugriff auf alle Datenbanken 
GRANT ALL PRIVILEGES ON reservierung_db.* TO 'admin_role';
GRANT ALL PRIVILEGES ON reservierung_audit_db.* TO 'admin_role';

-- Backend: Zugriff auf Reservierungsdatenbank
GRANT SELECT, INSERT, UPDATE, DELETE ON reservierung_db.* TO 'app_role';
GRANT INSERT ON reservierung_audit_db.audit_log TO 'app_role';