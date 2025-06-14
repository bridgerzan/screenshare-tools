$psHost = Get-Host
$psWindow = $psHost.UI.RawUI
$newSize = $psWindow.WindowSize
$newSize.Width = 80
$newSize.Height = 25
$psWindow.WindowSize = $newSize
$newBuffer = $psWindow.BufferSize
$newBuffer.Width = 80
$newBuffer.Height = 1000
$psWindow.BufferSize = $newBuffer
cls
$bannerLines = @(
" __      ______  _____ _______ ________   __",
" \ \    / / __ \|  __ \__   __|  ____\ \ / /",
"  \ \  / / |  | | |__) | | |  | |__   \ V / ",
"   \ \/ /| |  | |  _  /  | |  |  __|   > <  ",
"    \  / | |__| | | \ \  | |  | |____ / . \ ",
"     \/   \____/|_|  \_\ |_|  |______/_/ \_\"
)
$gradientColors = @("DarkMagenta", "Magenta", "Magenta", "Magenta", "White", "White")

function Show-BannerGradient {
    $lines = $bannerLines.Count
    for ($i = 0; $i -lt $lines; $i++) {
        $color = $gradientColors[$i]
        Write-Host $bannerLines[$i] -ForegroundColor $color
        Start-Sleep -Milliseconds 150
    }
    Write-Host ""
}
Show-BannerGradient
$desktopPath = [Environment]::GetFolderPath("Desktop")
$folderPath = Join-Path $desktopPath "screenshare"
if (-not (Test-Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

$url = "https://github.com/bridgerzan/screenshare-tools/raw/main/screenshare.zip"
$zipPath = Join-Path $folderPath "screenshare.zip"

function Write-ProgressMessage($message) {
    Write-Host $message -ForegroundColor White
}

Write-ProgressMessage "Downloading file..."

Invoke-WebRequest -Uri $url -OutFile $zipPath

Write-ProgressMessage "Download completed."

Start-Process $folderPath
pause
Write-Host "Press Enter to delete the downloaded ZIP file and exit..." -ForegroundColor Magenta
[void][System.Console]::ReadLine()

Remove-Item $zipPath -ErrorAction SilentlyContinue

Write-Host "ZIP file deleted. Exiting..." -ForegroundColor Magenta
