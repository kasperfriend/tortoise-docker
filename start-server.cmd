@echo off
REM Interactive start for the tortoise-wow server (db, realmd, mangosd).
REM Run this from the same folder as your docker-compose.yml.

setlocal

echo ============================
echo   Start Turtle WoW Server
echo ============================
echo.
docker compose ps
echo.
set /p CONFIRM=Start/restart the stack now? (Y/N): 
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    goto :end
)

echo.
echo Starting tortoise-wow server...
docker compose up -d

echo.
echo Containers starting. A first boot after a config or account change
echo can take several minutes (bot caches, travel data, etc. get rebuilt).
echo.
set /p WATCH=Watch live logs now? (Y/N): 
if /i "%WATCH%"=="Y" (
    docker compose logs -f mangosd
) else (
    docker compose ps
)

:end
echo.
pause
endlocal
