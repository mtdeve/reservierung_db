/*
 * Copyright (C) 2026 mtdeve
 * Licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root.
 */

DROP DATABASE IF EXISTS reservierung_db;
DROP DATABASE IF EXISTS reservierung_audit_db;

CREATE DATABASE reservierung_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

CREATE DATABASE reservierung_audit_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;