/*
 * Copyright (C) 2026 mtdeve
 * This project is licensed under the GNU Affero General Public License v3.0.
 * See the LICENSE file in the project root for more information.
 */

USE reservierung_db;

DELIMITER //

CREATE EVENT ev_cleanup_reservierung     -- event_scheduler muss aktiviert werden.
ON SCHEDULE EVERY 1 DAY                  -- für Mysql Die folgende Datei muss bearbeitet werden:
STARTS (CURRENT_DATE + INTERVAL 1 DAY)   -- C:>ProgramData>MySql>MySQL Server 8.x>My.ini
DO                                       -- Direkt unter [mysqld]  "event_scheduler=ON" hinzufügen
BEGIN                                    -- (ohne anführungszeichen)
    DELETE FROM reservierung r
    WHERE r.status = 'OFFEN'
      AND r.datum < NOW() - INTERVAL 1 DAY
      AND NOT EXISTS (
          SELECT 1
          FROM position p
          WHERE p.reservierung_id = r.reservierung_id
      );
END //

DELIMITER ;