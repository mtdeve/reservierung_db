@echo off
:: Setzt die Konsole auf UTF-8
chcp 65001 > nul
:: Setzt das Arbeitsverzeichnis auf den Speicherort der .bat-Datei
cd /d "%~dp0"

SET DB=reservierung_db
SET CNF="%~dp0mysql_credentials.cnf"
SET MIGRATION_DIR="..\migration"

:: Prüft ob die Konfigurationsdatei vorhanden ist
IF NOT EXIST %CNF% (
    echo [FEHLER] Konfigurationsdatei nicht gefunden: %CNF%
    echo Kopiere mysql_credentials.cnf.example und benenne sie um.
    pause
    exit /b 1
)

echo [START] Starte Datenbank-Setup aus: %CD%

mysql --defaults-file=%CNF% < "%MIGRATION_DIR%\000_create_database.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\001_create_tables.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\002_add_constraints.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\003_prozeduren.sql"

echo.
SET /P SEED_CHOICE="Testdaten (Seeds) importieren? (y/n): "

:: Führt den Seed-Import bei Bestätigung aus
IF /I "%SEED_CHOICE%"=="y" (
    mysql --defaults-file=%CNF% %DB% < "..\sql\100_seeds.sql"
    echo [INFO] Testdaten wurden importiert.
)

echo.
echo [FINISH] Setup abgeschlossen.
cd ..
pause