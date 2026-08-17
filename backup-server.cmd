@echo off
REM Backs up the full database (accounts, characters, world state) plus
REM a record of exactly which server commit was running at the time.
REM Safe to run anytime, including while the server is up.
REM Run this from the same folder as your docker-compose.yml.

setlocal enabledelayedexpansion

echo ==========================
echo   Backup Turtle WoW Data
echo ==========================
echo.

REM Read DB root password from .env if present, otherwise default to "root"
set DBPASS=root
for /f "tokens=1,2 delims==" %%A in ('findstr /b "DB_ROOT_PASSWORD=" .env 2^>nul') do set DBPASS=%%B

if not exist backups mkdir backups

REM Build a timestamp like 2026-08-17_1530 (locale-independent, from wmic)
for /f "skip=1" %%T in ('wmic os get localdatetime') do if not defined DTS set DTS=%%T
set STAMP=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%_%DTS:~8,2%%DTS:~10,2%

set DUMPFILE=backups\backup_%STAMP%.sql
set COMMITFILE=backups\backup_%STAMP%_commit.txt

echo This will back up all databases (accounts, characters, world data) to:
echo   %DUMPFILE%
echo.
set /p CONFIRM=Proceed? (Y/N): 
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    goto :end
)

echo.
echo Recording current server version...
docker compose exec -u turtle mangosd cat /opt/turtle/SOURCE_COMMIT > "%COMMITFILE%" 2>nul

echo Dumping databases (this can take a while for a large/old server)...
docker compose exec -T db mariadb-dump -uroot -p%DBPASS% --all-databases > "%DUMPFILE%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Something went wrong -- the dump may be incomplete. Check the
    echo error above before relying on this backup.
    goto :end
)

echo.
echo Done. Backup saved to:
echo   %DUMPFILE%
echo   %COMMITFILE%  (server version at time of backup)
echo.
echo Keep this file somewhere safe -- it contains everyone's account
echo password hashes, so don't upload it anywhere public.

:end
echo.
pause
endlocal
