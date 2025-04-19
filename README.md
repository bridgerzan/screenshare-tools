# bridgezan ss tools

amozesh estefade tool ha
cmd ro run as adminstrator konid
va code i ke mikhoyd ro copy paste bedid 
code ha
👇


all in one (use it on ss)
```powershell
$desktop = [System.Environment]::GetFolderPath("Desktop")
$folder = "$desktop\screenshare"
New-Item -ItemType Directory -Path $folder -Force
$zipPath = "$folder\screenshare.zip"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/screenshare.zip" -OutFile $zipPath
Start-Process $folder
```

CookedCli (oceancli runner)
```powershell
irm https://B2n.ir/CookedCLI | iex
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
