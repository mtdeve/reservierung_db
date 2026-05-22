@echo off
chcp 65001 > nul
cd /d "%~dp0"

SET DB=reservierung_db
SET CNF="%~dp0mysql_credentials.cnf"
SET MYSQL=mysql --defaults-file=%CNF% %DB%
SET TESTS="..\tests"

echo.
echo [TESTS] Starte Validierung...
echo ================================================

:: Tests die ERFOLGREICH sein muessen
call :run_success        "100_t_res_normale_buchung"  "TEST 100: Normale Buchung"
call :run_success        "102_t_res_defekt_wartung"   "TEST 102: Defekt und Wartung"
call :run_success        "104_t_res_beamer_buchung"   "TEST 104: Beamer Buchung"
call :run_success        "107_t_res_adress_reuse"     "TEST 107: Adress Wiederverwendung"
call :run_success        "108_t_res_zweiter_zeitraum" "TEST 108: Zweiter Zeitraum"

:: Tests die FEHLSCHLAGEN muessen (SIGNAL 45000 erwartet)
call :run_expected_fail  "101_t_res_overlap"          "TEST 101: Overlap"
call :run_expected_fail  "103_t_res_kein_item"        "TEST 103: Kein Item"
call :run_expected_fail  "105_t_res_beamer_engpass"   "TEST 105: Beamer Engpass"
call :run_expected_fail  "106_t_res_seed_overlap"     "TEST 106: Seed Overlap"

echo ================================================
echo [FINISH] Alle Tests abgeschlossen.
echo.
pause
exit /b 0

:: ------------------------------------------------
:: Funktion: Test der ERFOLGREICH sein muss
:: ------------------------------------------------
:run_success
type %TESTS%\_setup.sql %TESTS%\%~1.sql | %MYSQL%
IF %ERRORLEVEL% NEQ 0 (
    echo [FEHLGESCHLAGEN] %~2
) ELSE (
    echo [BESTANDEN]      %~2
)
exit /b 0

:: ------------------------------------------------
:: Funktion: Test der FEHLSCHLAGEN muss (SIGNAL erwartet)
:: ------------------------------------------------
:run_expected_fail
type %TESTS%\_setup.sql %TESTS%\%~1.sql | %MYSQL% > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [BESTANDEN]      %~2 ^(Fehler wie erwartet^)
) ELSE (
    echo [FEHLGESCHLAGEN] %~2 ^(Fehler wurde erwartet, kam aber nicht^)
)
exit /b 0