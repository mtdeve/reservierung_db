@echo off
:: Set console encoding to UTF-8
chcp 65001 > nul
:: Set working directory to the location of this .bat file
cd /d "%~dp0"

SET DB=reservierung_db
SET CNF="%~dp0mysql_credentials.cnf"
SET MIGRATION_DIR="..\migration"

:: Check if the configuration file exists
IF NOT EXIST %CNF% (
    echo [ERROR] Configuration file not found: %CNF%
    echo Please copy mysql_credentials.cnf.example and rename it.
    pause
    exit /b 1
)

echo [START] Starting database setup from: %CD%

:: Execute database migration files in sequential order
mysql --defaults-file=%CNF% < "%MIGRATION_DIR%\000_create_database.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\001_create_tables.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\002_add_constraints.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\003_prozeduren.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\004_functions.sql"
mysql --defaults-file=%CNF% %DB% < "%MIGRATION_DIR%\005_views.sql"

echo.
SET /P SEED_CHOICE="Import test data (Seeds)? (y/n): "

:: Executes seed import upon user confirmation
IF /I "%SEED_CHOICE%"=="y" (
    mysql --defaults-file=%CNF% %DB% < "..\sql\100_seeds.sql"
    echo [INFO] Test data imported successfully.
)

echo.
echo [FINISH] Setup completed.
cd ..
pause