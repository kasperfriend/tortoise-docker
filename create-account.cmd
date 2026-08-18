@echo off
REM Interactive account creation for the tortoise-wow server.
REM Just double-click this file (or run it) and answer the prompts.
REM Run it from the same folder as your docker-compose.yml.

setlocal enabledelayedexpansion

echo ================================
echo   Create a Turtle WoW Account
echo ================================
echo.

set /p USERNAME=Enter username: 
if "%USERNAME%"=="" (
    echo No username entered. Cancelled.
    goto :end
)

set /p PASSWORD=Enter password: 
if "%PASSWORD%"=="" (
    echo No password entered. Cancelled.
    goto :end
)

echo.
echo GM levels: 0 = normal player, 1-2 = moderator, 4 = full GM/admin
set /p GMLEVEL=Enter GM level (0-4, press Enter for 0/normal player): 
if "%GMLEVEL%"=="" set GMLEVEL=0

set REALMID=1

REM --- Read DB root password from .env (look for common variable names) ---
set "DBPASS="
for %%V in (MYSQL_ROOT_PASSWORD MARIADB_ROOT_PASSWORD DBPASS DB_PASS) do (
  for /f "usebackq tokens=1* delims==" %%A in (`findstr /b /i "%%V=" ".env" 2^>nul`) do (
    if not defined DBPASS set "DBPASS=%%B"
  )
)

REM fallback if not found
if not defined DBPASS (
  set "DBPASS=changeme"
)

REM remove any quotes and trim whitespace
if defined DBPASS (
  set "DBPASS=!DBPASS:"=!"
  for /f "tokens=* delims= " %%x in ("!DBPASS!") do set "DBPASS=%%x"
)

echo.
echo ------------------------------------
echo About to create this account:
echo   Username : %USERNAME%
echo   Password : %PASSWORD%
echo   GM level : %GMLEVEL%
echo ------------------------------------
set /p CONFIRM=Proceed? (Y/N): 
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    goto :end
)

echo.
echo Creating account '%USERNAME%'...
docker compose exec -u turtle mangosd sh -c "exec 3>/opt/turtle/run/mangosd.in; echo 'account create %USERNAME% %PASSWORD%' >&3; sleep 1; exec 3>&-"
timeout /t 2 /nobreak >nul

if not "%GMLEVEL%"=="0" (
    echo Setting GM level %GMLEVEL% for '%USERNAME%' on realm %REALMID%...
    docker compose exec -u turtle mangosd sh -c "exec 3>/opt/turtle/run/mangosd.in; echo 'account set gmlevel %USERNAME% %GMLEVEL% %REALMID%' >&3; sleep 1; exec 3>&-"
    timeout /t 2 /nobreak >nul
)

echo.
echo Verifying in database:
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "SELECT username, rank FROM tw_logon.account WHERE UPPER(username) = UPPER('%USERNAME%');"

:end
echo.
pause
endlocal
