@echo off
setlocal enabledelayedexpansion
chcp 65001
echo ⠀⠀⠀⢀⣴⣿⣶⣤⡀⠈⠂⠀⠀⠀⠀⠀⣠⣶⣿⢶⡄⠀⠀⠀⠀⠀
echo ⠀⠀⡰⣡⢫⡟⠻⣿⣿⣦⡀⠀⠀⠀⠀⣼⣿⣿⣿⠀⣿⣄⠱⡀⠀⠀
echo ⠀⢰⣡⠏⣼⠁⠀⠈⠻⣿⣿⣦⣀⣀⣼⣿⡿⠋⠈⡇⠹⣿⣆⠈⠄⠀
echo ⢀⢏⣸⣿⠇⠀⠀⠀⣠⡾⢻⣿⡿⣿⣿⣿⣷⡄⠀⢡⠀⢻⣿⣆⠈⡀
echo ⢸⣶⣿⠏⠀⠀⢀⣾⣫⣾⡞⣷⣿⣿⣿⣿⣿⣿⡆⠀⢧⠈⢿⣿⣆⠁
echo ⠘⠿⠟⠀⠀⠀⡾⣿⡿⡿⠀⠘⠃⠈⣉⡿⣿⣿⣿⡀⠈⠣⣌⣿⡟⠀
echo ⠀⠀⠀⠀⠀⠀⡇⣿⣿⡗⠿⠂⠀⠀⠙⠋⣿⣽⣿⡇⠀⠀⠀⠀⠀⠀
echo ⠀⠀⠀⠀⠀⠀⢃⢸⣿⣧⠀⠀⠀⠀⠀⠸⣿⣿⣿⣧⠀⠀                   bridgezan 
echo ⠀⠀⠀⠀⠀⠀⠀⣼⢻⣿⣧⣄⣀⣀⠤⢺⣹⣿⣿⣿⡄⠀⠀                   
echo ⠀⠀⠀⠀⠀⠀⠀⣿⣾⣿⣿⡿⡓⠄⡀⠸⡿⠿⠿⢿⣿⡄⠀⠀⠀⠀
echo ⠀⠀⠀⠀⠀⠀⢸⡿⠁⠀⠘⢣⠒⠀⣾⠿⡿⠃⠀⠀⢹⣷⡀⠀⠀⠀
echo ⠀⠀⠀⠀⠀⢀⣿⡇⠀⠀⠀⡄⠀⠀⠈⠀⠀⠀⠀⠀⢄⣿⢧⠀⠀⠀
echo ⠀⠀⠀⠀⠀⣼⣿⣇⠀⠀⠀⠀⣠⠦⢄⡀⠑⡀⠀⢠⢞⢻⣞⡆⠀⠀
echo ⠀⠀⠀⠀⠀⡏⣿⢹⠀⠀⠀⢠⠇⠹⠀⠈⣲⣄⣰⣋⣀⣼⣿⣷⠀⠀
echo ⠀⠀⠀⠀⠀⡇⢻⡾⡇⠀⠀⢸⣧⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⢸⠀⠀
echo ⠀⠀⠀⠀⠀⠀⢨⣿⣿⡀⠀⢸⣿⣿⣿⣿⣿⣿⣿⡟⡟⣽⣿⠈⠀⠀
echo ⠀⠀⠀⠀⠀⡠⠟⢡⣿⡇⠀⢸⣿⣿⣿⣿⣿⣿⡟⠁⡧⠃⡇⠀⠀⠀
echo ⠀⠀⠀⠀⠰⠀⢐⣡⣿⡇⠀⠀⣿⣿⣿⣿⣿⠟⠀⠀⡇⠀⠀⠁⠀⠀
echo ⠀⠀⠀⢀⠤⠚⠙⠻⣿⣇⠀⠀⣿⣿⣿⣿⡏⠀⡄⠀⡇⠀⠀⠀⠀⠀
echo ⠀⠀⠔⠁⠀⠀⠀⠀⠘⣿⡀⠀⢹⣿⣿⠞⠑⡄⠁⠀⠃⠀⠀⠀⠀

set services=PcaSvc CDPSvc DPS SysMain EventLog Appinfo DiagTrack Dnscache WSearch Schedule

echo ==============================================
echo   Service Status Checker
echo   by bridgezan
echo ==============================================
echo.

for %%S in (%services%) do (
    for /f "tokens=3 delims=: " %%A in ('sc query "%%S" ^| findstr "STATE"') do (
        if "%%A"=="STOPPED" (
            echo [91m%%S - : STOPPED[0m
        ) else (
            echo [92m%%S - : RUNNING[0m
        )
    )
)

echo.
echo checked
pause
