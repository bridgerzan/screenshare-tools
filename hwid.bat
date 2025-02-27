@echo off
::--------- dont read (pls)--------------------------
:variables
set green=[0;32m
set red=[0;31m
set reset=[0m
set bold=[1m
set white=[0m
set blue=[96m
set grey=[38;5;238m
set r=[0m
set -=%blue%-%white%
:: ---------------------------------------------------
cls
Title HWID Extractor
color 0E
set /p WEBHOOK_URL=%grey%Enter your Webhook URL: %blue%
:Menu
cls
setlocal enabledelayedexpansion
chcp 65001
cls
%white%
echo ⠀⠀⠀⢀⣴⣿⣶⣤⡀⠈⠂⠀⠀⠀⠀⠀⣠⣶⣿⢶⡄⠀⠀⠀⠀⠀
echo ⠀⠀⡰⣡⢫⡟⠻⣿⣿⣦⡀⠀⠀⠀⠀⣼⣿⣿⣿⠀⣿⣄⠱⡀⠀⠀
echo ⠀⢰⣡⠏⣼⠁⠀⠈⠻⣿⣿⣦⣀⣀⣼⣿⡿⠋⠈⡇⠹⣿⣆⠈⠄⠀
echo ⢀⢏⣸⣿⠇⠀⠀⠀⣠⡾⢻⣿⡿⣿⣿⣿⣷⡄⠀⢡⠀⢻⣿⣆⠈⡀
echo ⢸⣶⣿⠏⠀⠀⢀⣾⣫⣾⡞⣷⣿⣿⣿⣿⣿⣿⡆⠀⢧⠈⢿⣿⣆⠁
echo ⠘⠿⠟⠀⠀⠀⡾⣿⡿⡿⠀⠘⠃⠈⣉⡿⣿⣿⣿⡀⠈⠣⣌⣿⡟⠀
echo ⠀⠀⠀⠀⠀⠀⡇⣿⣿⡗⠿⠂⠀⠀⠙⠋⣿⣽⣿⡇⠀⠀⠀⠀⠀⠀
echo ⠀⠀⠀⠀⠀⠀⢃⢸⣿⣧⠀⠀⠀⠀⠀⠸⣿⣿⣿⣧⠀⠀         %blue%bridgezan%white% 
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
echo.
echo %blue%[%white%1%blue%]%grey% -%white% Extract HWID
echo %blue%[%white%2%blue%]%grey% -%white% Quit
echo %blue%[%white%3%blue%]%grey% -%white% Change Webhook URL
echo %blue%[%white%4%blue%]%grey% -%white% Clear Logs 
echo.
set /p input=Select an option:%blue%
if /i "%input%" equ "1" goto Hwid
if /i "%input%" equ "2" goto Exit
if /i "%input%" equ "3" goto ChangeWebhook
if /i "%input%" equ "4" goto ClearLogs 
timeout /t 2 >nul
goto Menu
:ChangeWebhook
cls
echo %white%Changing Webhook URL%blue%...
set /p WEBHOOK_URL=%white%Enter new Webhook URL:%blue% 
echo %white%Webhook updated successfully%blue%!
timeout /t 2 >nul
goto Menu
:Hwid
cls
set "RESULTS_DIR=%USERPROFILE%\Desktop\bridgezan-hwid"
md "%RESULTS_DIR%" 2>nul
set "HWID_FILE=%RESULTS_DIR%\%UserName%_HWID.txt"
set "HWID_HTML=%RESULTS_DIR%\%UserName%_HWID.html"
echo ============================================== > "%HWID_FILE%"
echo                HWID Information               >> "%HWID_FILE%"
echo ============================================== >> "%HWID_FILE%"
echo. >> "%HWID_FILE%"
echo User Name(s): >> "%HWID_FILE%"
echo ---------------------------------------------- >> "%HWID_FILE%"
echo Computer Name: %ComputerName% >> "%HWID_FILE%"
echo User Domain  : %UserDomain% >> "%HWID_FILE%"
echo Windows Version: >> "%HWID_FILE%"
powershell "(Get-WmiObject Win32_OperatingSystem).Caption" >> "%HWID_FILE%"
echo ---------------------------------------------- >> "%HWID_FILE%"
echo ---------------------------------------------- >> "%HWID_FILE%"
powershell "(Get-WmiObject Win32_ComputerSystemProduct).UUID" >> "%HWID_FILE%"
powershell "Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty ProcessorId" >> "%HWID_FILE%"
powershell "getmac" >> "%HWID_FILE%"
echo ---------------------------------------------- >> "%HWID_FILE%"

echo. >> "%HWID_FILE%"
echo ---------------------------------------------- >> "%HWID_FILE%"
echo System Model: >> "%HWID_FILE%"
powershell "(Get-WmiObject Win32_ComputerSystem).Model" >> "%HWID_FILE%"
echo Manufacturer: >> "%HWID_FILE%"
powershell "(Get-WmiObject Win32_ComputerSystem).Manufacturer" >> "%HWID_FILE%"
echo ============================================== >> "%HWID_FILE%"

echo %white%Uploading files%blue%...
curl -H "Accept: application/json" -H "Content-Type:multipart/form-data" -X POST -F "file=@%HWID_FILE%" -F "file=@%HWID_HTML%" -F "payload_json={\"content\":\"%UserName% HWID Report\"}" %WEBHOOK_URL%
echo %white%Done%blue%!
pause
start "" "%HWID_FILE%"
timeout /t 2 >nul
goto Menu
:ClearLogs
cls
del /q "%RESULTS_DIR%\*.txt" "%RESULTS_DIR%\*.html"
cd ..
cd ..
cd C:\Users\%username%\Desktop
del /q %RESULTS_DIR%
echo %white%Logs cleared%blue%!
timeout /t 2 >nul
goto Menu
:Exit
exit /b /min 