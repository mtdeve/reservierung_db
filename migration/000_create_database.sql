/*
 * Copyright (C) 2026 Il mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:      000_create_database.sql
-- PROJEKT:     Reservierung DB
-- ZIELSETZUNG: Erstellung der Datenbankinstanz und Basiskonfiguration
-- ============================================================
DROP DATABASE IF EXISTS reservierung_db;
CREATE DATABASE reservierung_db;

-- utf8mb4 falls ohne cnf-Datei ausgeführt wird
-- auf alle Dateien als standardmaßige Praxis. Es verhindert Fehler.
USE reservierung_db;
/*!40101 SET NAMES utf8mb4 */; 

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- ============================================================
-- ZIELSETZUNG: Trennung der Audit- und Anwendungsdaten zur
-- Verbesserung der Nachvollziehbarkeit und Sicherheit.
-- Eine separate Datenbank ermöglicht eine getrennte Verwaltung,
-- Sicherung und Zugriffskontrolle der Protokolldaten.
-- ============================================================
CREATE DATABASE IF NOT EXISTS reservierung_audit_db;

USE reservierung_audit_db;

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- ============================================================
-- HINWEIS: Alle Skripte verwenden eine einheitliche Namenskonvention.
-- Bei der Namensgebung wird stets ein verständlicher und neutraler Standard angestrebt,
-- z. B.: v_ = Variable, uq_ = Unique, pro_ = Prozedur, fk_ = Fremdschlüssel usw.
-- Dies erleichtert die Wartbarkeit, Lesbarkeit und Zusammenarbeit im Team.
-- ============================================================