@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cls
set desktop=%userprofile%\Desktop
set patchFolder=%desktop%\patch
set existsFile=%patchFolder%\exists.txt
set notExistsFile=%patchFolder%\notexists.txt
if not exist "!patchFolder!" (
    mkdir "!patchFolder!"
)
set files=p.txt patch.txt "Search results.txt"
set found=false
set countExists=0
set countNotExists=0
echo. > "!existsFile!"
echo. > "!notExistsFile!"
set startTime=%time%
color 07
cls
echo ⠀⠀⠀⢀⣴⣿⣶⣤⡀⠈⠂⠀⠀⠀⠀⠀⣠⣶⣿⢶⡄⠀⠀⠀⠀⠀
echo ⠀⠀⡰⣡⢫⡟⠻⣿⣿⣦⡀⠀⠀⠀⠀⣼⣿⣿⣿⠀⣿⣄⠱⡀⠀⠀
echo ⠀⢰⣡⠏⣼⠁⠀⠈⠻⣿⣿⣦⣀⣀⣼⣿⡿⠋⠈⡇⠹⣿⣆⠈⠄⠀
echo ⢀⢏⣸⣿⠇⠀⠀⠀⣠⡾⢻⣿⡿⣿⣿⣿⣷⡄⠀⢡⠀⢻⣿⣆⠈⡀
echo ⢸⣶⣿⠏⠀⠀⢀⣾⣫⣾⡞⣷⣿⣿⣿⣿⣿⣿⡆⠀⢧⠈⢿⣿⣆⠁
echo ⠘⠿⠟⠀⠀⠀⡾⣿⡿⡿⠀⠘⠃⠈⣉⡿⣿⣿⣿⡀⠈⠣⣌⣿⡟⠀
echo ⠀⠀⠀⠀⠀⠀⡇⣿⣿⡗⠿⠂⠀⠀⠙⠋⣿⣽⣿⡇⠀⠀⠀⠀⠀⠀
echo ⠀⠀⠀⠀⠀⠀⢃⢸⣿⣧⠀⠀⠀⠀⠀⠸⣿⣿⣿⣧⠀⠀         bridgezan 
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
echo Checking files...
echo.

for %%f in (%files%) do (
    if !found! equ false (
        for /f "usebackq delims=" %%a in (%%f) do (
            set file=%%a
            if exist "!file!" (
                echo %%a >> "!existsFile!"
                set /a countExists+=1
            ) else (
                echo %%a >> "!notExistsFile!"
                set /a countNotExists+=1
            )
        )
        set found=true
    )
)
echo exits:
for /f "delims=" %%a in ('type "!existsFile!"') do (
    if not "%%a"==""     if not "%%a"=="" echo %%a  ‍‌
)
echo.

echo not exits:
for /f "delims=" %%a in ('type "!notExistsFile!"') do (
    if not "%%a"=="" echo %%a  ‍‌
)
echo.
echo --- Summary ---
echo Total files checked: !countExists! files exist, !countNotExists! files do not exist.
echo.
echo --- Ending ---
echo Done. Script finished at: %date% %time%
pause
