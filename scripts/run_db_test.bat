@echo off
:: Set console encoding to UTF-8
chcp 65001 > nul
:: Set working directory to the location of this .bat file
cd /d "%~dp0"

SET DB=reservierung_db
SET CNF="%~dp0mysql_credentials.cnf"
SET MYSQL=mysql --defaults-file=%CNF% %DB%
SET TESTS="..\tests"

echo.
echo [TESTS] Starting validation...
echo ================================================
echo.

:: Tests that MUST SUCCESS
call :run_success        "100_t_res_normale_buchung"     "TEST 100: Normal Booking"
call :run_success        "102_t_res_defekt_wartung"      "TEST 102: Defect and Maintenance"
call :run_success        "104_t_res_beamer_buchung"      "TEST 104: Beamer Booking"
call :run_success        "107_t_res_adress_reuse"        "TEST 107: Address Reuse"

:: Tests that MUST FAIL (SIGNAL 45000 expected)
call :run_expected_fail  "101_t_res_overlap"             "TEST 101: Overlap"
call :run_expected_fail  "103_t_res_kein_item"           "TEST 103: No Item Available"
call :run_expected_fail  "105_t_res_beamer_engpass"      "TEST 105: Beamer Shortage"
call :run_expected_fail  "106_t_res_seed_overlap"        "TEST 106: Seed Overlap"
call :run_expected_fail  "109_t_res_datum_vergangenheit" "TEST 109: Start Date in Past"

echo ================================================
echo [FINISH] All tests completed.
echo.
pause
exit /b 0

:: ------------------------------------------------
:: Function: Test that must complete successfully
:: ------------------------------------------------
:run_success
(type %TESTS%\_setup.sql & type %TESTS%\%~1.sql) 2>nul | %MYSQL%
IF %ERRORLEVEL% NEQ 0 (
    echo [FAILED] %~2
) ELSE (
    echo [PASSED] %~2
)
exit /b 0

:: ------------------------------------------------
:: Function: Test that must fail (SIGNAL expected)
:: ------------------------------------------------
:run_expected_fail
(type %TESTS%\_setup.sql & type %TESTS%\%~1.sql) 2>nul | %MYSQL% > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [PASSED] %~2 ^(Error as expected^)
) ELSE (
    echo [FAILED] %~2 ^(Error was expected, but transaction succeeded^)
)
exit /b 0
cd..