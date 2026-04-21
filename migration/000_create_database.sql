/*
 * Copyright (C) 2026 Il mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

-- ============================================================
-- SKRIPT:    000_create_database.sql
-- PROJEKT:   Reservierung DB
-- ZIELSETZUNG: Erstellung der Datenbankinstanz und Basiskonfiguration
-- ============================================================
-- 
DROP DATABASE IF EXISTS reservierung_db;
CREATE DATABASE reservierung_db;
USE reservierung_db;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
