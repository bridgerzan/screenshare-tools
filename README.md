# bridgezan ss tools

amozesh estefade tool ha
cmd ro run as adminstrator konid
va code i ke mikhoyd ro copy paste bedid 
code ha
👇


all in one (use it on ss)
```powershell
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/all-in-one-beta.ps1')"
```
Downloader
```powershell
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/downloader.ps1)
```
CookedCli (oceancli runner)
```powershell
iex (irm 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/CookedCli.ps1')
```

Task Scheduler Checker
```powershell
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/Task-Scheduler-Checker.ps1')"
```

services checker
```powershell
irm https://B2n.ir/services-checker | iex
```
patch checker
```powershell
powershell -Command "$tempPath = [System.IO.Path]::Combine($env:TEMP, 'patch-checker.bat'); Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/patch-checker.bat' -OutFile $tempPath; Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', $tempPath -WindowStyle Normal;"
```

hwid extractor
```powershell
powershell -Command "$tempPath = [System.IO.Path]::Combine($env:TEMP, 'hwid.bat'); Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/hwid.bat' -OutFile $tempPath; Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', $tempPath -WindowStyle Normal;"
```
file checker
```powershell
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/file-checker.ps1')"
```
