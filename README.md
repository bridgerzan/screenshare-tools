# bridgezan ss tools

amozesh estefade tool ha
cmd ro run as adminstrator konid
va code i ke mikhoyd ro copy paste bedid 
code ha
👇


ss tool
```powershell
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/SSTool.ps1')"
```


code rbw bam
```powershell
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/coderrbw-ss.ps1')"
```

Task Scheduler Checker
```powershell
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/Task-Scheduler-Checker.ps1')"
```


services checker
```powershell
powershell -Command "$tempPath = [System.IO.Path]::Combine($env:TEMP, 'services.bat'); Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/services.bat' -OutFile $tempPath; Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', $tempPath -WindowStyle Normal;"
```

patch checker
```powershell
powershell -Command "$tempPath = [System.IO.Path]::Combine($env:TEMP, 'patch-checker.bat'); Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/patch-checker.bat' -OutFile $tempPath; Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', $tempPath -WindowStyle Normal;"
```
hwid extractor
```powershell
powershell -Command "$tempPath = [System.IO.Path]::Combine($env:TEMP, 'hwid.bat'); Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/hwid.bat' -OutFile $tempPath; Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', $tempPath -WindowStyle Normal;"
```
