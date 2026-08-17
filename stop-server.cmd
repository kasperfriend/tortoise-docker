@echo off
REM Interactive stop for the tortoise-wow server (db, realmd, mangosd).
REM Containers are stopped, not deleted -- all data (accounts, characters,
REM world data) is preserved and will still be there next time you start.
REM Run this from the same folder as your docker-compose.yml.

setlocal

echo ===========================
echo   Stop Turtle WoW Server
echo ===========================
echo.
docker compose ps
echo.
set /p CONFIRM=Stop the server now? Players/bots currently online will be disconnected. (Y/N): 
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    goto :end
)

echo.
echo Stopping tortoise-wow server...
docker compose stop

echo.
docker compose ps

:end
echo.
pause
endlocal
