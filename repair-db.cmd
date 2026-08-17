@echo off
REM Interactive database check/repair for the tortoise-wow server.
REM Safe to run anytime -- REPAIR TABLE does nothing harmful to a
REM healthy table. Good after an unclean shutdown or a crashed container,
REM or if bots/characters mysteriously stop working.
REM Run this from the same folder as your docker-compose.yml.
REM The db container must be running (start-server.cmd first if needed).

setlocal

echo ==============================
echo   Repair Turtle WoW Database
echo ==============================
echo.

set DBPASS=root

set /p CHECKCONFIRM=Check core tables for corruption now? (Y/N): 
if /i not "%CHECKCONFIRM%"=="Y" (
    echo Cancelled.
    goto :end
)

echo.
echo Checking tables...
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "CHECK TABLE tw_char.characters;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "CHECK TABLE tw_char.character_inventory;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "CHECK TABLE tw_logon.account;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "CHECK TABLE tw_world.creature;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "CHECK TABLE tw_world.gameobject;"

echo.
echo Look through the results above. Anything that says "OK" is fine.
echo Anything else (e.g. "corrupt", "crashed") needs repairing.
echo.
set /p REPAIRCONFIRM=Repair all these tables now? Safe even if some were already OK. (Y/N): 
if /i not "%REPAIRCONFIRM%"=="Y" (
    echo Skipping repair.
    goto :end
)

echo.
echo Repairing tables...
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "REPAIR TABLE tw_char.characters;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "REPAIR TABLE tw_char.character_inventory;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "REPAIR TABLE tw_logon.account;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "REPAIR TABLE tw_world.creature;"
docker compose exec -T db mariadb -uroot -p%DBPASS% -e "REPAIR TABLE tw_world.gameobject;"

echo.
set /p RESTARTCONFIRM=Repair done. Restart mangosd now to use the clean data? (Y/N): 
if /i "%RESTARTCONFIRM%"=="Y" (
    docker compose restart mangosd
    echo mangosd restarted.
) else (
    echo Remember to restart mangosd later: docker compose restart mangosd
)

:end
echo.
pause
endlocal
