@echo off
REM Manually updates the server to the latest published image, with a
REM safety backup beforehand and a sanity check afterward.
REM Run this from the same folder as your docker-compose.yml.

setlocal enabledelayedexpansion

echo ==========================
echo   Update Turtle WoW Server
echo ==========================
echo.

REM Read DB root password from .env if present, otherwise default to "root"
set DBPASS=root
for /f "tokens=1,2 delims==" %%A in ('findstr /b "DB_ROOT_PASSWORD=" .env 2^>nul') do set DBPASS=%%B

echo Current server version:
docker compose exec -u turtle mangosd cat /opt/turtle/SOURCE_COMMIT 2>nul
echo.

echo Updating pulls the latest published image and applies any new
echo database migrations automatically. This can change server behavior
echo and, if it's been a long time since your last update, may apply
echo many migrations at once.
echo.
set /p BACKUPCONFIRM=Back up the database first? Strongly recommended. (Y/N): 
if /i "%BACKUPCONFIRM%"=="Y" (
    call backup-server.cmd
)

echo.
set /p UPDATECONFIRM=Proceed with the update now? (Y/N): 
if /i not "%UPDATECONFIRM%"=="Y" (
    echo Cancelled.
    goto :end
)

echo.
echo Pulling the latest image...
docker compose pull

echo.
echo Recreating the server with the new image...
docker compose up -d --force-recreate mangosd realmd

echo.
echo Update applied. New server version:
timeout /t 5 /nobreak >nul
docker compose exec -u turtle mangosd cat /opt/turtle/SOURCE_COMMIT 2>nul

echo.
set /p WATCHCONFIRM=Watch the startup log now to see migrations run? Recommended. (Y/N): 
if /i "%WATCHCONFIRM%"=="Y" (
    echo Press Ctrl+C when you see "World server is up and running".
    docker compose logs -f mangosd
)

echo.
echo Quick sanity check -- these numbers should match what you had before:
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "SELECT COUNT(*) AS accounts FROM tw_logon.account;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "SELECT COUNT(*) AS characters FROM tw_char.characters;"

echo.
echo If anything looks wrong, restore from the backup you just made
echo (see the .sql file in the backups folder) before continuing to play.

:end
echo.
pause
endlocal
