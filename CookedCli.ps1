if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
    exit
}
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.PrivateData.ErrorForegroundColor = "Red"
$Host.PrivateData.WarningForegroundColor = "Yellow"
Clear-Host
Write-Host @"
   _____            _            _  _____ _ _
  / ____|          | |          | |/ ____| (_)
 | |     ___   ___ | | _____  __| | |    | |_
 | |    / _ \ / _ \| |/ / _ \/ _` | |    | | |
 | |___| (_) | (_) |   <  __/ (_| | |____| | |
  \_____\___/ \___/|_|\_\___|\__,_|\_____|_|_|
                 by bridgezan
"@ -ForegroundColor Cyan
$desktopPath = [Environment]::GetFolderPath("Desktop")
$folderPath = Join-Path $desktopPath "CookedCLI"
$psexecPath = Join-Path $folderPath "PsExec.exe"
$oceanPath = Join-Path $folderPath "oceancli.exe"
$psexecUrl = "https://abrehamrahi.ir/o/public/xOyBcjow/"
$oceanUrl = "https://anticheat.ac/downloads/general/cli"
if (-not (Test-Path $folderPath)) {
    Write-Host "`n[1/5] Creating folder..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $folderPath | Out-Null
} else {
    Write-Host "`n[1/5] Folder already exists." -ForegroundColor DarkGray
}
if (-not (Test-Path $psexecPath)) {
    Write-Host "`n[2/5] Downloading PsExec.exe..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $psexecUrl -OutFile $psexecPath -ErrorAction Stop
        Write-Host "PsExec.exe downloaded successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error downloading PsExec.exe: $_" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "`n[2/5] PsExec.exe already exists." -ForegroundColor DarkGray
}
Write-Host "`n[3/5] Do you want to download oceancli.exe automatically?" -ForegroundColor Yellow
Write-Host "[Y] Yes, (not recommanded)" -ForegroundColor Cyan
Write-Host "[N] No, I will download it manually and paste it in the folder" -ForegroundColor Magenta
$choice = Read-Host "Choose Y or N"
if ($choice.ToLower() -eq "y") {
    try {
        Invoke-WebRequest -Uri $oceanUrl -OutFile $oceanPath -ErrorAction Stop
        Write-Host "oceancli.exe downloaded successfully." -ForegroundColor Green
    } catch {
        Write-Host "`n[!] Failed to download oceancli.exe automatically." -ForegroundColor Red
        Write-Host "→ Please download manually from:" -ForegroundColor Cyan
        Write-Host $oceanUrl -ForegroundColor Magenta
        Write-Host "Then paste it into the folder below and type Y to continue." -ForegroundColor Yellow
        Write-Host $folderPath -ForegroundColor Cyan
        do {
            $confirm = Read-Host "Type Y when you pasted oceancli.exe"
        } until ($confirm.ToLower() -eq "y")

        if (-not (Test-Path $oceanPath)) {
            Write-Host "`n[x] oceancli.exe not found in folder" -ForegroundColor Red
            exit
        }
    }
} elseif ($choice.ToLower() -eq "n") {
    Write-Host "`n→ Please download manually from:" -ForegroundColor Cyan
    Write-Host $oceanUrl -ForegroundColor Magenta
    Write-Host "Then paste it into the folder below and type Y to continue." -ForegroundColor Yellow
    Write-Host $folderPath -ForegroundColor Cyan
    do {
        $confirm = Read-Host "Type Y when you’ve pasted oceancli.exe"
    } until ($confirm.ToLower() -eq "y")
    if (-not (Test-Path $oceanPath)) {
        Write-Host "`n[×] oceancli.exe not found in folder. Exiting." -ForegroundColor Red
        exit
    }
} else {
    Write-Host "[!] Invalid choice. Exiting." -ForegroundColor Red
    exit
}
Write-Host "`n[4/5] Enter your PIN :" -ForegroundColor Yellow
$pin = Read-Host "PIN"
if (-not $pin) {
    Write-Host "PIN is empty. Exiting." -ForegroundColor Red
    exit
}
$cmdToRun = 'cmd.exe /c cd /d "' + $folderPath + '" && start "" /HIGH oceancli.exe ' + $pin
$psexecArgs = "-accepteula -i -s $cmdToRun"
Write-Host "`n[5/5] Launching OceanCLI" -ForegroundColor Yellow
try {
    Start-Process -FilePath $psexecPath -ArgumentList $psexecArgs -WorkingDirectory $folderPath
    Write-Host "`nOceanCLI launched successfully" -ForegroundColor Green
} catch {
    Write-Host "Error launching CMD: $_" -ForegroundColor Red
}
Write-Host "`ncomplete. Press any key to exit this window." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit
