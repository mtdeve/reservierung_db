@echo off
:: Set console encoding to UTF-8
chcp 65001 > nul
:: Set working directory to the location of this .bat file
cd /d "%~dp0"

SET DB=reservierung_db
SET CNF="%~dp0mysql_credentials.cnf"
SET SCHEMA_DIR="..\schema"
SET DATA_DIR="..\data"

:: Check if the configuration file exists
IF NOT EXIST %CNF% (
    echo [ERROR] Configuration file not found: %CNF%
    echo Please copy mysql_credentials.cnf.example and rename it.
    pause
    exit /b 1
)

echo [START] Starting database setup from: %CD%

:: Execute database Schema files in sequential order
mysql --defaults-file=%CNF% < "%SCHEMA_DIR%\000_create_database.sql"
mysql --defaults-file=%CNF% %DB% < "%SCHEMA_DIR%\001_create_tables.sql"
mysql --defaults-file=%CNF% %DB% < "%SCHEMA_DIR%\002_add_constraints.sql"
mysql --defaults-file=%CNF% %DB% < "%SCHEMA_DIR%\003_functions.sql"
mysql --defaults-file=%CNF% %DB% < "%SCHEMA_DIR%\004_procedures.sql"
mysql --defaults-file=%CNF% %DB% < "%SCHEMA_DIR%\005_views.sql"
mysql --defaults-file=%CNF% %DB% < "%SCHEMA_DIR%\006_triggers.sql"
mysql --defaults-file=%CNF% %DB% < "%SCHEMA_DIR%\007_access.sql"

echo [START 2] Starting database setup from: %CD%
:: Execute additional SQL scripts in the sql directory
mysql --defaults-file=%CNF% %DB% < "%DATA_DIR%\100_create_users.sql"
mysql --defaults-file=%CNF% %DB% < "%DATA_DIR%\101_verify_installation.DATA"

echo.
SET /P SEED_CHOICE="Import first config data (Seeds)? (y/n): "

:: Executes seed import upon user confirmation
IF /I "%SEED_CHOICE%"=="y" (
    mysql --defaults-file=%CNF% %DB% < "%DATA_DIR%\102_seeds_config_data.sql"
    echo [INFO] Test data imported successfully.
)

echo.
echo [FINISH] Setup completed.
cd ..
pause